require "set"

module Toolforge
  class UpdateDataWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    def perform
      contests = Contest.all.to_a

      Year.where(storicized: false).each do |year|
        period_start = DateTime.parse("#{ENV["PERIOD_START"]} #{year.year} 00:00+2")
        period_end = DateTime.parse("#{ENV["PERIOD_END"]} #{year.year} 23:59+2")
        reg_start = Date.parse("#{ENV["PERIOD_START"]} #{year.year}") - 3.days
        reg_end = Date.parse("#{ENV["PERIOD_END"]} #{year.year}")

        contests.each do |contest|
          import_contest_photos(contest, year, period_start, period_end, reg_start, reg_end)
        end

        update_year_statistics(year, contests)
      end
    end

    private

    def import_contest_photos(contest, year, period_start, period_end, reg_start, reg_end)
      puts "Ottengo la categoria della regione #{contest.name} (#{contest.cat_name(year)})..."

      photos = WikimediaReplicaClient.fetch_category_photos(contest.cat_name(year))
      return if photos.empty?

      existing_names = Set.new
      photos.map { |p| p["title"] }.uniq.each_slice(1000) do |slice|
        existing_names.merge(Photo.where(name: slice).pluck(:name))
      end

      new_photos = photos.reject do |photo|
        existing_names.include?(photo["title"]) ||
          photo["timestamp"].nil? ||
          !photo["timestamp"].to_time.between?(period_start, period_end)
      end
      return if new_photos.empty?

      new_pageids = new_photos.map { |p| p["pageid"] }
      wlmids_by_pageid = WikimediaReplicaClient.fetch_wlmids_for_pageids(new_pageids)
      upload_sources_by_pageid = detect_upload_sources(new_pageids)

      special_titles = if year.special
                         WikimediaReplicaClient.fetch_category_member_titles(
                           "#{contest.cat_name(year)} #{year.special_category.to_s.strip}"
                         )
                       end

      grouped_photos = new_photos.group_by { |p| [p["user"], p["userid"]] }
      creators_by_username, creators_by_userid = preload_creators(grouped_photos.keys)

      missing_usernames = grouped_photos.keys.reject do |username, userid|
        creators_by_username.key?(username) || (userid && creators_by_userid.key?(userid))
      end.filter_map(&:first).uniq

      registrations = if missing_usernames.any?
                        WikimediaReplicaClient.fetch_user_registrations(missing_usernames)
                      else
                        {}
                      end

      photos_to_be_inserted = []
      now = Time.current

      grouped_photos.each do |(username, userid), user_photos|
        creator = find_or_create_creator(
          username: username,
          userid: userid,
          registrations: registrations,
          creators_by_username: creators_by_username,
          creators_by_userid: creators_by_userid,
          contest: contest,
          year: year,
          reg_start: reg_start,
          reg_end: reg_end
        )
        next if creator.nil?

        user_photos.each do |photo|
          raw_wlmid = wlmids_by_pageid[photo["pageid"].to_i]
          wlmid, new_monument = resolve_wlmid_and_archive!(raw_wlmid)

          photos_to_be_inserted << {
            pageid: photo["pageid"],
            name: photo["title"],
            creator_id: creator.id,
            contest_id: contest.id,
            photodate: photo["timestamp"],
            wlmid: wlmid,
            new_monument: new_monument,
            upload_source: upload_sources_by_pageid[photo["pageid"].to_i] || "other",
            created_at: now,
            updated_at: now,
            year_id: year.id,
            special: special_titles ? special_titles.include?(photo["title"]) : false
          }
        end
      end

      Photo.insert_all(photos_to_be_inserted) unless photos_to_be_inserted.empty?
    end

    def preload_creators(user_keys)
      usernames = user_keys.filter_map(&:first).uniq
      userids = user_keys.filter_map(&:last).uniq

      creators_by_username = {}
      creators_by_userid = {}
      return [creators_by_username, creators_by_userid] if usernames.empty? && userids.empty?

      scope = if usernames.any? && userids.any?
                Creator.where(username: usernames).or(Creator.where(userid: userids))
              elsif usernames.any?
                Creator.where(username: usernames)
              else
                Creator.where(userid: userids)
              end

      scope.each do |creator|
        creators_by_username[creator.username] = creator if creator.username
        creators_by_userid[creator.userid] = creator if creator.userid
      end

      [creators_by_username, creators_by_userid]
    end

    def find_or_create_creator(username:, userid:, registrations:, creators_by_username:, creators_by_userid:, contest:, year:, reg_start:, reg_end:)
      existing = creators_by_username[username] || (userid && creators_by_userid[userid])
      return existing if existing

      registration = registrations[username]
      creator = Creator.create(username: username, userid: userid, creationdate: registration)
      unless creator.persisted?
        creator = Creator.where(username: username).or(Creator.where(userid: userid)).first
        return nil if creator.nil?
      end

      creators_by_username[creator.username] = creator if creator.username
      creators_by_userid[creator.userid] = creator if creator.userid

      if !registration.nil? && registration.to_date.between?(reg_start, reg_end)
        creator.update!(proveniencecontest: contest.id, year: year)
      end

      creator
    end

    def resolve_wlmid_and_archive!(raw_wlmid)
      return [nil, false] if raw_wlmid.blank?

      candidates = wlmid_candidates(raw_wlmid)
      matches = NoPhotoMonument.where(wlmid: candidates).to_a
      return [raw_wlmid, false] if matches.empty?

      rank = candidates.each_with_index.to_h
      unarchived = matches.reject(&:archived).min_by { |m| rank[m.wlmid] || Float::INFINITY }
      if unarchived
        unarchived.update!(archived: true)
        return [unarchived.wlmid, true]
      end

      existing = matches.min_by { |m| rank[m.wlmid] || Float::INFINITY }
      [existing.wlmid, false]
    end

    def wlmid_candidates(raw_wlmid)
      candidates = [raw_wlmid]
      current = raw_wlmid
      while current.start_with?("0") && current.length > 1
        current = current[1..]
        candidates << current
      end
      candidates.uniq
    end

    def update_year_statistics(year, contests)
      puts "Inizio salvataggio del conto dei creatori e delle nuove foto."

      contests.each do |contest|
        contestyear = ContestYear.find_by(contest: contest, year: year)
        next if contestyear.nil?

        photos_scope = Photo.where(year: year, contest: contest)

        # Creatori con foto partecipanti
        creators = photos_scope.distinct.count(:creator_id)

        # Utenti iscritti appositamente per il concorso
        creatorsapposta = year.new_creators(contest: contest).count

        # Nuove foto
        new_monuments = photos_scope.where(new_monument: true).count
        new_monuments_percentage = contestyear.count.to_i > 0 ? (new_monuments.to_f / contestyear.count.to_f * 100) : 0

        # Monumenti ritratti
        depicted_monuments = photos_scope.pluck(:wlmid).uniq.count
        special_depicted_monuments = photos_scope.where(special: true).pluck(:wlmid).uniq.count
        depicted_monuments_percentage = contestyear.monuments.to_i > 0 ? (depicted_monuments.to_f / contestyear.monuments.to_f * 100.0) : 0

        contestyear.update!(
          creators: creators,
          new_monuments: new_monuments,
          new_monuments_percentage: new_monuments_percentage,
          creatorsapposta: creatorsapposta,
          depicted_monuments: depicted_monuments,
          depicted_monuments_percentage: depicted_monuments_percentage,
          special_depicted_monuments: special_depicted_monuments
        )
      end

      # Creators dell'intero anno
      global_photos = Photo.where(year: year)
      total_creators = global_photos.pluck(:creator_id).uniq.count
      global_depicted_monuments = global_photos.pluck(:wlmid).uniq.count
      global_special_depicted_monuments = global_photos.where(special: true).pluck(:wlmid).uniq.count
      new_monuments = global_photos.where(new_monument: true).count

      if (nophoto = Nophoto.where(year: year, regione: nil).last) && nophoto.monuments.to_i > 0
        global_depicted_monuments_percentage = global_depicted_monuments.to_f / nophoto.monuments.to_f * 100.0
      else
        global_depicted_monuments_percentage = 0
      end

      year.update!(
        creators_count: total_creators,
        depicted_monuments: global_depicted_monuments,
        depicted_monuments_percentage: global_depicted_monuments_percentage,
        special_depicted_monuments: global_special_depicted_monuments,
        new_monuments: new_monuments
      )

      ## CONTEGGIO PERCENTUALE SUL TOTALE
      contests.each do |contest|
        contestyear = ContestYear.find_by(contest: contest, year: year)
        next if contestyear.nil?

        participants_percent_of_total = total_creators.to_i > 0 ? (contestyear.creators.to_f / total_creators.to_f * 100) : 0
        contestyear.update!(participants_percent_of_total: participants_percent_of_total)
      end

      ## AGGIORNAMENTO DELL'ANNO COME STORICIZZATO SE TUTTO È CONCLUSO
      if DateTime.now > (DateTime.parse("#{ENV["PERIOD_END"]} #{year.year}") + 1.months) && year.photos.count == year.total
        year.update!(storicized: true)
      end
    end

    def detect_upload_sources(pageids)
      return {} if pageids.empty?

      sources = {}
      Toolforge::UpdateUploadSourceWorker::SOURCE_CATEGORIES.each do |source_key, categories|
        categories.each do |cat|
          matched = WikimediaReplicaClient.fetch_pageids_in_category(pageids, cat)
          matched.each { |pid| sources[pid] ||= source_key }
        end
      end
      sources
    end
  end
end
