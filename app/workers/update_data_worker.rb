require "addressable/uri"
class UpdateDataWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: :all
  })

  def perform
    Year.where(storicized: false).each do |year|
      Contest.all.each do |contest|
        puts "Ottengo la categoria della regione #{contest.name} (#{contest.cat_name(year)})..."

        # Facendo uso del generator categorymembers, ottiene le informazioni sulle foto nella categoria d'elezione
        commons_api = "https://commons.wikimedia.org/w/api.php"
        request = HTTParty.get(commons_api, query: {action: :query, prop: :imageinfo, iiprop: 'user|timestamp|userid', generator: :categorymembers, gcmtitle: contest.cat_name(year), gcmdir: :newer, gcmlimit: 500, format: :json}, uri_adapter: Addressable::URI).to_h

        photolist = request.try(:[], "query").try(:[], "pages")

        # Procede con la continuazione
        while !request["continue"].nil?
          request = HTTParty.get(commons_api, query: {action: :query, prop: :imageinfo, iiprop: 'user|timestamp|userid', generator: :categorymembers, gcmtitle: contest.cat_name(year), gcmdir: :newer, gcmcontinue: request["continue"]["gcmcontinue"], gcmlimit: 500, format: :json}, uri_adapter: Addressable::URI).to_h
          photolist.merge!(request["query"]["pages"]) # Unisce i due hash
        end

        next if photolist.nil?

        # Rimuove le fotografie che già esistono in memoria o che non sono foto (namespace 6)
        photolist.reject! { |_, photo| Photo.exists?(name: photo['title']) || photo['ns'] != 6 }

        # Facendo uso del generator categorymembers, ottiene i contenuti delle pagine
        revisions_request = HTTParty.get(commons_api, query: {action: :query, prop: :revisions, rvslots: "main", rvprop: :content, generator: :categorymembers, gcmlimit: 50, gcmnamespace: 6, gcmtitle: contest.cat_name(year), gcmdir: :newer, format: :json}, uri_adapter: Addressable::URI).to_h

        revisions_list = revisions_request.try(:[], "query").try(:[], "pages")

        # Procede con la continuazione
        while !revisions_request["continue"].nil?
            revisions_request = HTTParty.get(commons_api, query: {action: :query, prop: :revisions, rvslots: "main", rvprop: :content, generator: :categorymembers, gcmlimit: 50, gcmnamespace: 6, gcmtitle: contest.cat_name(year), gcmdir: :newer, format: :json, gcmcontinue: revisions_request["continue"]["gcmcontinue"]}, uri_adapter: Addressable::URI).to_h
          revisions_list.merge!(revisions_request["query"]["pages"]) # Unisce i due hash
        end

        # ottiene elenco membri categoria speciale se presente
        if year.special
          specials = HTTParty.get(commons_api, query: {action: :query, list: :categorymembers, cmtitle: contest.cat_name(year) + year.special_category, cmdir: :newer, cmlimit: 500, format: :json}, uri_adapter: Addressable::URI).to_h

          special_photolist = request.try(:[], "query").try(:[], "categorymembers")

          # Procede con la continuazione
          while !specials["continue"].nil?
            specials = HTTParty.get(commons_api, query: {action: :query, list: :categorymembers, cmtitle: contest.cat_name(year) + year.special_category, cmdir: :newer, cmlimit: 500, cmcontinue: request["continue"]["cmcontinue"], format: :json}).to_h
            special_photolist += request["query"]["categorymembers"] # Unisce i due hash
          end

          special_titles = special_photolist.pluck("titles")
        end

        @photos_to_be_inserted = []

        photolist.group_by { |_,v| [v['imageinfo'][0]['user'], v['imageinfo'][0]['userid']] }.each do |userinfo, photos|

          # Recupero le singole informazioni per l'identificazione
          username = userinfo[0]
          userid = userinfo[1]

          # Se non c'è l'utente, lo crea, altrimenti lo individua normalmente
          if Creator.exists?(username: username) || Creator.exists?(userid: userid)
            creator = Creator.where(username: username).or(Creator.where(userid: userid)).first
          else
            # Recupera le informazioni sull'utente da Commons
            userinfo = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {action: :query, meta: :globaluserinfo, guiuser: username, format: :json}, uri_adapter: Addressable::URI).to_h["query"]["globaluserinfo"]

            creator = Creator.create(username: username, userid: userid, creationdate: userinfo['registration'])

            # Verifica se l'utente si è iscritto appositamente per il concorso
            unless userinfo['registration'].nil?
              creator.update!(proveniencecontest: contest.id) if userinfo['registration'].to_date.between?(Date.parse("#{ENV["PERIOD_START"]} #{year.year}") - 3.days, Date.parse("#{ENV["PERIOD_END"]} #{year.year}"))
            end
          end

          photos.each do |_, photo|
            # Shortcut alle informazioni più proprie dell'immagine
            photoinfo = photo['imageinfo'][0]

            # Procede solo se la fotografia è stata scattata. nel periodo di Settembre
            next unless photoinfo['timestamp'].to_time.between?(DateTime.parse("#{ENV["PERIOD_START"]} #{year.year} 00:00+2"), DateTime.parse("#{ENV["PERIOD_END"]} #{year.year} 23:59+2"))

            page_content = revisions_list[photo['pageid'].to_s]["revisions"][0]["slots"]["main"]["*"]

            wlmid = page_content.match(/{{Monumento italiano\|(\d{2}\w\d*)\|anno=\d*}}/).try(:[], 1)

            if !wlmid.nil? && (nophoto = NoPhotoMonument.find_by(wlmid: wlmid))
              new_monument = true
              nophoto.destroy
            else
              new_monument = false
            end
            special_titles&.include?(photo['title']) ? special = true : special = false

            @photos_to_be_inserted.push({pageid: photo['pageid'], name: photo['title'], creator_id: creator.id, contest_id: contest.id, photodate: photoinfo['timestamp'], wlmid: wlmid, new_monument: new_monument, created_at: DateTime.now, updated_at: DateTime.now, year_id: year.id, special: special})
          end
        end

        Photo.insert_all(@photos_to_be_inserted) unless @photos_to_be_inserted.empty?
      end

      puts 'Inizio salvataggio del conto dei creatori.'
      Contest.all.each do |contest|
        # Creatori con foto partecipanti
        creators = Creator.includes(:photos).select { |m| m.photos.where(contest: contest).any? }.count
        contest.update!(creators: creators)

        # Utenti iscritti appositamente per il concorso
        creatorsapposta = Creator.where(proveniencecontest: contest.id).count
        contest.update!(creatorsapposta: creatorsapposta)
      end

    end
    if DateTime.now > (DateTime.parse("#{ENV["PERIOD_END"]} #{year.year}") + 1.months)
      year.update!(storicized: true)
    end
  end
end
