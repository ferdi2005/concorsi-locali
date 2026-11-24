require "set"
require "uri"

class DashboardInsights
  CACHE_TTL = 2.hours

  def self.cache_version
    Rails.cache.read("dashboard_insights:version") || 1
  end

  def self.clear_cache!
    Rails.cache.write("dashboard_insights:version", cache_version + 1)
  end

  def self.monuments_coverage(regione: nil, contest_id: nil)
    key = "dashboard_insights:v#{cache_version}:monuments:#{regione || 'all'}:#{contest_id || 'all'}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_monuments_coverage(regione: regione, contest_id: contest_id)
    end
  end

  def self.exif_summary(years:, contest_id: nil)
    key = "dashboard_insights:v#{cache_version}:exif:#{contest_id || 'all'}:#{years.map(&:id).join('-')}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_exif_summary(years: years, contest_id: contest_id)
    end
  end

  def self.pageviews_summary(years:, contest_id: nil)
    key = "dashboard_insights:v#{cache_version}:pageviews:#{contest_id || 'all'}:#{years.map(&:id).join('-')}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_pageviews_summary(years: years, contest_id: contest_id)
    end
  end

  def self.top_monuments(year:, contest_id: nil, limit: 15)
    return [] if year.nil?

    key = "dashboard_insights:v#{cache_version}:top_monuments:#{year.id}:#{contest_id || 'all'}:#{limit}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_top_monuments(year: year, contest_id: contest_id, limit: limit)
    end
  end

  def self.top_monuments_all_years(contest_id: nil, limit: 20)
    key = "dashboard_insights:v#{cache_version}:top_monuments_all:#{contest_id || 'all'}:#{limit}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_top_monuments_all_years(contest_id: contest_id, limit: limit)
    end
  end

  SEGMENT_LABELS = {
    "new_only_wlm" => "Nuovi solo WLM",
    "returning_only_wlm" => "Già registrati solo WLM",
    "occasional" => "Occasionali fuori settembre",
    "year_round_100_plus" => "Attivi tutto l'anno (100+ file)"
  }.freeze

  def self.top_camera_models(year: nil, contest_id: nil, limit: 10)
    key = "dashboard_insights:v#{cache_version}:top_cameras:#{year&.id || 'all'}:#{contest_id || 'all'}:#{limit}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_top_camera_models(year: year, contest_id: contest_id, limit: limit)
    end
  end

  def self.edition_insights(year:, contest_id: nil)
    return nil if year.nil?

    key = "dashboard_insights:v#{cache_version}:edition_insights:#{year.id}:#{contest_id || 'all'}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_edition_insights(year: year, contest_id: contest_id)
    end
  end

  def self.historical_trends(years:, contest_id: nil, regione: nil)
    key = "dashboard_insights:v#{cache_version}:historical_trends:#{contest_id || 'all'}:#{regione || 'all'}:#{years.map(&:id).join('-')}"
    Rails.cache.fetch(key, expires_in: CACHE_TTL) do
      compute_historical_trends(years: years, contest_id: contest_id, regione: regione)
    end
  end

  class << self
    private

    def compute_monuments_coverage(regione: nil, contest_id: nil)
      scope = Monument.all
      scope = scope.where(regione: regione) if regione.present?
      return nil unless scope.exists?

      total_m = scope.count
      no_photo_m = scope.where(photos_count: 0).count

      sentinels = {
        total: total_m,
        without_photo: no_photo_m,
        with_photo_total: total_m - no_photo_m,
        without_wikipedia: scope.where(has_wikipedia: false).count,
        without_commons: scope.where(has_commons_category: false).count,
        with_wlm_without_commons: scope.where("photos_count > 0").where(has_commons_category: false).count,
        with_wlm_without_p18: scope.where("photos_count > 0").where(has_p18: false).count,
        with_mic_catalog: scope.where.not(mic_catalog_id: [nil, ""]).count,
        recent_since_1950: scope.where("inception_year >= ?", 1950).count
      }

      small_scope = scope.small_municipality(5000)
      small_total = small_scope.count
      small_no_photo = small_scope.where(photos_count: 0).count
      small_no_photo_share = no_photo_m > 0 ? (small_no_photo.to_f / no_photo_m * 100.0).round(1) : 0.0

      # Quota di foto WLM che finiscono nei comuni sotto i 5.000 abitanti
      small_wlmids = small_scope.where.not(wlmid: [nil, ""]).pluck(:wlmid, :normalized_wlmid).flatten.compact.uniq
      photo_scope = Photo.where.not(wlmid: [nil, ""])
      photo_scope = photo_scope.where(contest_id: contest_id) if contest_id.present?
      total_photos_with_wlmid = photo_scope.count
      small_photos_count = if small_wlmids.any? && total_photos_with_wlmid > 0
                             cnt = 0
                             small_wlmids.each_slice(2000) do |slice|
                               cnt += photo_scope.where(wlmid: slice).count
                             end
                             cnt
                           else
                             0
                           end
      small_photos_share = total_photos_with_wlmid > 0 ? (small_photos_count.to_f / total_photos_with_wlmid * 100.0).round(1) : 0.0

      city_scope = scope.where.not(city_item: [nil, ""])
      untouched_municipalities = city_scope.group(:city_item).having("SUM(photos_count) = 0").count.size
      total_municipalities = city_scope.distinct.count(:city_item)

      small_municipalities = {
        total_monuments: small_total,
        no_photo_monuments: small_no_photo,
        no_photo_share: small_no_photo_share,
        photos_count: small_photos_count,
        photos_share: small_photos_share,
        untouched_municipalities: untouched_municipalities,
        total_municipalities: total_municipalities
      }

      type_rows = scope.group(:monument_type).pluck(
        :monument_type,
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(CASE WHEN photos_count = 0 THEN 1 ELSE 0 END)")
      )
      types_stats = type_rows.map do |mtype, tot, noph|
        tot_i = tot.to_i
        noph_i = noph.to_i
        {
          type: mtype.presence || "altro / non classificato",
          total: tot_i,
          no_photo: noph_i,
          no_photo_pct: tot_i > 0 ? (noph_i.to_f / tot_i * 100.0).round(1) : 0.0
        }
      end.sort_by { |r| -r[:total] }

      {
        sentinels: sentinels,
        small_municipalities: small_municipalities,
        types_stats: types_stats
      }
    end

    def compute_exif_summary(years:, contest_id: nil)
      base = Photo.where.not(exif_checked_at: nil)
      base = base.where(contest_id: contest_id) if contest_id.present?
      return nil unless base.exists?

      by_year = {}
      latest_year_with_exif = nil

      years.each do |year|
        scope = base.where(year_id: year.id)
        checked = scope.count
        next if checked == 0

        latest_year_with_exif = year
        year_start = Time.utc(year.year.to_i, 1, 1)
        prev_year_start = Time.utc(year.year.to_i - 1, 1, 1)

        archive_before_year = scope.where("taken_at IS NOT NULL AND taken_at < ?", year_start).count
        archive_before_prev = scope.where("taken_at IS NOT NULL AND taken_at < ?", prev_year_start).count
        smartphone = scope.where(device_category: "smartphone").count
        camera = scope.where(device_category: "camera").count
        no_exif = scope.where(has_exif: false).count

        # Dispositivo prevalente per partecipante
        user_dev_rows = scope.group(:creator_id, :device_category).count
        per_user = Hash.new { |h, k| h[k] = Hash.new(0) }
        user_dev_rows.each do |(cid, cat), cnt|
          per_user[cid][cat.to_s] += cnt
        end
        total_users = per_user.size
        smartphone_users = per_user.values.count { |h| h["smartphone"] > 0 && h["smartphone"] >= h["camera"] }
        camera_users = per_user.values.count { |h| h["camera"] > 0 && h["camera"] > h["smartphone"] }

        by_year[year.id] = {
          checked: checked,
          archive_pct: (archive_before_year.to_f / checked * 100.0).round(1),
          archive_prev_pct: (archive_before_prev.to_f / checked * 100.0).round(1),
          smartphone_pct: (smartphone.to_f / checked * 100.0).round(1),
          camera_pct: (camera.to_f / checked * 100.0).round(1),
          no_exif_pct: (no_exif.to_f / checked * 100.0).round(1),
          smartphone_users_pct: total_users > 0 ? (smartphone_users.to_f / total_users * 100.0).round(1) : 0.0,
          camera_users_pct: total_users > 0 ? (camera_users.to_f / total_users * 100.0).round(1) : 0.0
        }
      end

      # File senza EXIF per canale di caricamento
      source_rows = base.where.not(upload_source: [nil, ""]).group(:upload_source).pluck(
        :upload_source,
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(CASE WHEN has_exif = false THEN 1 ELSE 0 END)")
      )
      no_exif_by_source = source_rows.map do |src, tot, no_ex|
        tot_i = tot.to_i
        no_ex_i = no_ex.to_i
        {
          source: src,
          total: tot_i,
          no_exif: no_ex_i,
          no_exif_pct: tot_i > 0 ? (no_ex_i.to_f / tot_i * 100.0).round(1) : 0.0
        }
      end.sort_by { |r| -r[:total] }

      # Modelli di fotocamera più usati su tutte le edizioni
      top_models = compute_top_camera_models(year: nil, contest_id: contest_id, limit: 10)

      {
        by_year: by_year,
        no_exif_by_source: no_exif_by_source,
        top_models: top_models
      }
    end

    def compute_pageviews_summary(years:, contest_id: nil)
      usage_base = PhotoUsage.active.joins(:photo)
      usage_base = usage_base.where(photos: { contest_id: contest_id }) if contest_id.present?
      return nil unless usage_base.exists?

      views_by_page = WikiPageMonthlyView.group(:wiki, :page_title).sum(:views)
      by_year = {}
      all_pages = Set.new

      years.each do |year|
        usages = usage_base.where(photos: { year_id: year.id }).distinct.pluck(:wiki, :page_title)
        next if usages.empty?

        usages.each { |pair| all_pages.add(pair) }
        langs = usages.map(&:first).uniq.size
        page_views = usages.map { |pair| views_by_page[pair].to_i }.sort.reverse
        total_views = page_views.sum
        top12_views = page_views.first(12).sum

        by_year[year.id] = {
          pages_count: usages.size,
          wikis_count: langs,
          total_views: total_views,
          top12_share: total_views > 0 ? (top12_views.to_f / total_views * 100.0).round(1) : 0.0
        }
      end

      top_pages = all_pages.map do |wiki, title|
        domain = PhotoUsage.project_domain_for_wiki(wiki)
        url = domain ? "https://#{domain}/wiki/#{URI.encode_www_form_component(title.tr(' ', '_')).gsub('+', '%20')}" : nil
        {
          wiki: wiki,
          page_title: title.tr("_", " "),
          url: url,
          views: views_by_page[[wiki, title]].to_i
        }
      end.select { |p| p[:views] > 0 }.sort_by { |p| -p[:views] }.first(10)

      {
        by_year: by_year,
        top_pages: top_pages
      }
    end

    def compute_top_monuments(year:, contest_id: nil, limit: 15)
      raw_list = if contest_id.nil? && year.year_analytic&.top_monuments.present?
                   year.year_analytic.top_monuments.first(limit).map do |m|
                     { wlmid: m["wlmid"], photos: m["photos"].to_i, authors: m["authors"].to_i }
                   end
                 else
                   scope = Photo.where(year_id: year.id).where.not(wlmid: [nil, ""])
                   scope = scope.where(contest_id: contest_id) if contest_id.present?
                   scope
                     .group(:wlmid)
                     .order(Arel.sql("COUNT(*) DESC"))
                     .limit(limit)
                     .pluck(:wlmid, Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT creator_id)"))
                     .map { |wlmid, cnt, authors| { wlmid: wlmid, photos: cnt.to_i, authors: authors.to_i } }
                 end

      return [] if raw_list.empty?

      norms = raw_list.map { |r| AnalyticsCalculator.normalize_wlmid(r[:wlmid]) }.uniq
      monuments_by_norm = Monument.where(normalized_wlmid: norms).index_by(&:normalized_wlmid)

      raw_list.map do |row|
        norm = AnalyticsCalculator.normalize_wlmid(row[:wlmid])
        mon = monuments_by_norm[norm]
        row.merge(
          item: mon&.item,
          label: mon&.label,
          city: mon&.city,
          regione: mon&.regione,
          monument_type: mon&.monument_type
        )
      end
    end

    def compute_top_monuments_all_years(contest_id: nil, limit: 20)
      scope = Photo.where.not(wlmid: [nil, ""])
      scope = scope.where(contest_id: contest_id) if contest_id.present?

      rows = scope
        .group(:wlmid)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .pluck(
          :wlmid,
          Arel.sql("COUNT(*)"),
          Arel.sql("COUNT(DISTINCT creator_id)"),
          Arel.sql("COUNT(DISTINCT year_id)")
        )
      return [] if rows.empty?

      norms = rows.map { |wlmid, _, _, _| AnalyticsCalculator.normalize_wlmid(wlmid) }.uniq
      monuments_by_norm = Monument.where(normalized_wlmid: norms).index_by(&:normalized_wlmid)

      rows.map do |wlmid, cnt, authors, editions|
        norm = AnalyticsCalculator.normalize_wlmid(wlmid)
        mon = monuments_by_norm[norm]
        {
          wlmid: wlmid,
          photos: cnt.to_i,
          authors: authors.to_i,
          editions: editions.to_i,
          item: mon&.item,
          label: mon&.label,
          city: mon&.city,
          regione: mon&.regione,
          monument_type: mon&.monument_type
        }
      end
    end

    def compute_top_camera_models(year: nil, contest_id: nil, limit: 10)
      scope = Photo.where.not(exif_checked_at: nil)
      scope = scope.where(year_id: year.id) if year.present?
      scope = scope.where(contest_id: contest_id) if contest_id.present?
      total = scope.count
      return [] if total == 0

      rows = scope
        .where.not(camera_model: [nil, ""])
        .group(:camera_make, :camera_model, :device_category)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .pluck(
          :camera_make,
          :camera_model,
          :device_category,
          Arel.sql("COUNT(*)"),
          Arel.sql("COUNT(DISTINCT creator_id)")
        )

      rows.map do |make, model, dev_cat, cnt, users_cnt|
        cnt_i = cnt.to_i
        {
          make: make,
          model: model,
          device_category: dev_cat,
          photos: cnt_i,
          share: (cnt_i.to_f / total * 100.0).round(1),
          users: users_cnt.to_i
        }
      end
    end

    def compute_edition_insights(year:, contest_id: nil)
      scope = Photo.where(year_id: year.id)
      scope = scope.where(contest_id: contest_id) if contest_id.present?

      creator_counts = scope.group(:creator_id).count
      total_creators = creator_counts.size
      total_photos = creator_counts.values.sum

      bucket_defs = [
        ["1 foto", 1..1],
        ["2-10 foto", 2..10],
        ["11-50 foto", 11..50],
        ["51-200 foto", 51..200],
        ["Oltre 200 foto", 201..Float::INFINITY]
      ]
      participant_buckets = bucket_defs.map do |label, range|
        matched = creator_counts.values.select { |cnt| range.cover?(cnt) }
        c_cnt = matched.size
        p_cnt = matched.sum
        {
          label: label,
          creators: c_cnt,
          creators_pct: pct_val(c_cnt, total_creators),
          photos: p_cnt,
          photos_pct: pct_val(p_cnt, total_photos)
        }
      end

      contest_obj = contest_id.present? ? Contest.find_by(id: contest_id) : nil
      new_creator_ids = year.new_creators(contest: contest_obj).pluck(:id)
      newcomers_profile = compute_newcomers_profile(scope, new_creator_ids)

      activity_segments = compute_activity_segments(year, scope, creator_counts, contest_id)

      multiregional = if contest_id.nil?
                        compute_multiregional(scope, total_creators, total_photos)
                      else
                        []
                      end

      top_uploaders = if contest_id.nil?
                        compute_edition_top_uploaders(year, scope)
                      else
                        []
                      end

      top_viewed_pages = compute_edition_top_viewed_pages(year, contest_id)

      {
        participant_buckets: participant_buckets,
        newcomers_profile: newcomers_profile,
        activity_segments: activity_segments,
        multiregional: multiregional,
        top_uploaders: top_uploaders,
        top_viewed_pages: top_viewed_pages
      }
    end

    def compute_newcomers_profile(scope, new_creator_ids)
      if new_creator_ids.empty?
        return {
          newcomers_count: 0,
          photos_total: 0,
          checked_photos: 0,
          no_exif_pct: 0.0,
          smartphone_pct: 0.0,
          camera_pct: 0.0,
          smartphone_users_pct: 0.0,
          by_source: []
        }
      end

      new_photos = scope.where(creator_id: new_creator_ids)
      photos_total = new_photos.count
      checked_scope = new_photos.where.not(exif_checked_at: nil)
      checked_photos = checked_scope.count

      if checked_photos > 0
        no_exif = checked_scope.where(has_exif: false).count
        smartphone = checked_scope.where(device_category: "smartphone").count
        camera = checked_scope.where(device_category: "camera").count

        per_user = {}
        checked_scope.group(:creator_id, :device_category).count.each do |(cid, cat), cnt|
          per_user[cid] ||= {}
          per_user[cid][cat.to_s] = cnt.to_i
        end
        total_checked_users = per_user.size
        smartphone_users = per_user.values.count { |h| h["smartphone"].to_i > 0 && h["smartphone"].to_i >= h["camera"].to_i }

        source_rows = checked_scope.where.not(upload_source: [nil, ""]).group(:upload_source).pluck(
          :upload_source,
          Arel.sql("COUNT(*)"),
          Arel.sql("SUM(CASE WHEN has_exif = false THEN 1 ELSE 0 END)")
        )
        by_source = source_rows.map do |src, tot, no_ex|
          tot_i = tot.to_i
          no_ex_i = no_ex.to_i
          {
            source: src,
            total: tot_i,
            no_exif: no_ex_i,
            no_exif_pct: pct_val(no_ex_i, tot_i)
          }
        end.sort_by { |r| -r[:total] }
      else
        no_exif = 0
        smartphone = 0
        camera = 0
        total_checked_users = 0
        smartphone_users = 0
        by_source = []
      end

      {
        newcomers_count: new_creator_ids.size,
        photos_total: photos_total,
        checked_photos: checked_photos,
        no_exif_pct: pct_val(no_exif, checked_photos),
        smartphone_pct: pct_val(smartphone, checked_photos),
        camera_pct: pct_val(camera, checked_photos),
        smartphone_users_pct: pct_val(smartphone_users, total_checked_users),
        by_source: by_source
      }
    end

    def compute_activity_segments(year, scope, creator_counts, contest_id)
      act_scope = CreatorYearlyActivity.where(year_id: year.id)
      if contest_id.present?
        cids = creator_counts.keys
        return nil if cids.empty?

        act_scope = act_scope.where(creator_id: cids)
      end

      rows = act_scope.pluck(:creator_id, :uploader_segment, :wlm_uploads_count, :non_wlm_uploads_year)
      return nil if rows.empty?

      segment_order = %w[new_only_wlm returning_only_wlm occasional year_round_100_plus]
      grouped = {}
      segment_order.each { |seg| grouped[seg] = { creators: 0, photos: 0 } }

      top_candidates = []
      rows.each do |cid, seg, wlm_cnt, non_wlm_cnt|
        in_scope_photos = contest_id.present? ? creator_counts[cid].to_i : wlm_cnt.to_i
        if grouped.key?(seg)
          grouped[seg][:creators] += 1
          grouped[seg][:photos] += in_scope_photos
        end
        top_candidates << [in_scope_photos, wlm_cnt.to_i, non_wlm_cnt.to_i]
      end

      total_creators = grouped.values.sum { |v| v[:creators] }
      total_photos = grouped.values.sum { |v| v[:photos] }

      segments = segment_order.map do |seg|
        info = grouped[seg]
        {
          segment: seg,
          label: SEGMENT_LABELS[seg],
          creators: info[:creators],
          creators_pct: pct_val(info[:creators], total_creators),
          photos: info[:photos],
          photos_pct: pct_val(info[:photos], total_photos)
        }
      end

      top50 = top_candidates.sort_by { |in_scope_p, _, _| -in_scope_p }.first(50)
      sep_shares = top50.filter_map do |_, wlm_cnt, non_wlm_cnt|
        denom = wlm_cnt + non_wlm_cnt
        denom > 0 ? (wlm_cnt.to_f / denom * 100.0) : nil
      end
      top50_year_round_count = top50.count { |_, _, non_wlm_cnt| non_wlm_cnt >= 100 }

      {
        segments: segments,
        top50_sample_size: top50.size,
        top50_median_sep_share: median_val(sep_shares),
        top50_year_round_count: top50_year_round_count
      }
    end

    def compute_multiregional(scope, total_creators, total_photos)
      rows = scope.group(:creator_id).pluck(
        :creator_id,
        Arel.sql("COUNT(DISTINCT contest_id)"),
        Arel.sql("COUNT(*)")
      )
      return [] if rows.empty?

      buckets = {
        "1 regione" => { creators: 0, photos: 0 },
        "2 regioni" => { creators: 0, photos: 0 },
        "3 o più regioni" => { creators: 0, photos: 0 }
      }
      rows.each do |_, regions_cnt, photos_cnt|
        rc = regions_cnt.to_i
        label = if rc <= 1
                  "1 regione"
                elsif rc == 2
                  "2 regioni"
                else
                  "3 o più regioni"
                end
        buckets[label][:creators] += 1
        buckets[label][:photos] += photos_cnt.to_i
      end

      buckets.map do |label, info|
        {
          label: label,
          creators: info[:creators],
          creators_pct: pct_val(info[:creators], total_creators),
          photos: info[:photos],
          photos_pct: pct_val(info[:photos], total_photos)
        }
      end
    end

    def compute_edition_top_uploaders(year, scope, limit: 20)
      top_rows = scope
        .group(:creator_id)
        .order(Arel.sql("COUNT(*) DESC"))
        .limit(limit)
        .pluck(:creator_id, Arel.sql("COUNT(*)"), Arel.sql("COUNT(DISTINCT contest_id)"))
      return [] if top_rows.empty?

      top_ids = top_rows.map(&:first)
      creators_by_id = Creator.where(id: top_ids).index_by(&:id)
      editions_by_id = Photo.where(creator_id: top_ids).group(:creator_id).distinct.count(:year_id)
      non_wlm_by_id = CreatorYearlyActivity.where(year_id: year.id, creator_id: top_ids).pluck(:creator_id, :non_wlm_uploads_year).to_h

      top10_counts_by_id = Hash.new(0)
      per_year_counts = Photo.group(:year_id, :creator_id).count
      by_year = {}
      per_year_counts.each do |(yid, cid), cnt|
        by_year[yid] ||= []
        by_year[yid] << [cid, cnt]
      end
      by_year.each_value do |pairs|
        pairs.sort_by { |_, cnt| -cnt }.first(10).each do |cid, _|
          top10_counts_by_id[cid] += 1
        end
      end

      reg_window = year.registration_window_range
      top_rows.filter_map do |cid, photos_cnt, contests_cnt|
        creator = creators_by_id[cid]
        next if creator.nil?

        {
          creator_id: cid,
          username: creator.username,
          is_new: !creator.creationdate.nil? && reg_window.cover?(creator.creationdate),
          photos_count: photos_cnt.to_i,
          contests_count: contests_cnt.to_i,
          editions_count: editions_by_id[cid].to_i,
          top10_years_count: top10_counts_by_id[cid].to_i,
          non_wlm_uploads_year: non_wlm_by_id[cid]
        }
      end
    end

    def compute_edition_top_viewed_pages(year, contest_id, limit: 10)
      usage_scope = PhotoUsage.active.joins(:photo).where(photos: { year_id: year.id })
      usage_scope = usage_scope.where(photos: { contest_id: contest_id }) if contest_id.present?
      pairs = usage_scope.distinct.pluck(:wiki, :page_title)
      return [] if pairs.empty?

      views_by_page = WikiPageMonthlyView.group(:wiki, :page_title).sum(:views)
      pairs.map do |wiki, title|
        domain = PhotoUsage.project_domain_for_wiki(wiki)
        url = domain ? "https://#{domain}/wiki/#{URI.encode_www_form_component(title.tr(' ', '_')).gsub('+', '%20')}" : nil
        {
          wiki: wiki,
          page_title: title.tr("_", " "),
          url: url,
          views: views_by_page[[wiki, title]].to_i
        }
      end.select { |p| p[:views] > 0 }.sort_by { |p| -p[:views] }.first(limit)
    end

    def compute_historical_trends(years:, contest_id: nil, regione: nil)
      ordered_years = years.sort_by { |y| y.year.to_i }
      photo_scope = contest_id.present? ? Photo.where(contest_id: contest_id) : Photo.all

      {
        wlm_retention: compute_wlm_retention(ordered_years, photo_scope, contest_id),
        nophoto_history: compute_nophoto_history(ordered_years, regione),
        territory_and_type_trends: compute_territory_and_type_trends(ordered_years, photo_scope),
        wlmid_quality: compute_wlmid_quality(ordered_years, photo_scope),
        seasonality: compute_seasonality(ordered_years, photo_scope)
      }
    end

    def compute_wlm_retention(ordered_years, photo_scope, contest_id)
      pairs = photo_scope.distinct.pluck(:year_id, :creator_id)
      creators_by_year_id = {}
      editions_count_by_creator = {}
      all_creator_ids_set = Set.new

      pairs.each do |yid, cid|
        creators_by_year_id[yid] ||= Set.new
        creators_by_year_id[yid].add(cid)
        editions_count_by_creator[cid] = (editions_count_by_creator[cid] || 0) + 1
        all_creator_ids_set.add(cid)
      end

      all_creator_ids = all_creator_ids_set.to_a
      creationdates = all_creator_ids.any? ? Creator.where(id: all_creator_ids).pluck(:id, :creationdate).to_h : {}

      active_years = ordered_years.select { |y| creators_by_year_id[y.id]&.any? }
      yoy_rows = []

      (0...(active_years.size - 1)).each do |idx|
        y = active_years[idx]
        next_y = active_years[idx + 1]
        current_set = creators_by_year_id[y.id]
        next_set = creators_by_year_id[next_y.id]

        later_union = Set.new
        ((idx + 1)...active_years.size).each do |lidx|
          later_union.merge(creators_by_year_id[active_years[lidx].id])
        end

        reg_win = y.registration_window_range
        new_set = Set.new
        current_set.each do |cid|
          cd = creationdates[cid]
          new_set.add(cid) if cd && reg_win.cover?(cd)
        end
        veteran_set = current_set - new_set

        returned_next = (current_set & next_set).size
        returned_any_later = (current_set & later_union).size
        new_returned_next = (new_set & next_set).size
        veteran_returned_next = (veteran_set & next_set).size

        yoy_rows << {
          year: y.year,
          next_year: next_y.year,
          participants: current_set.size,
          returned_next: returned_next,
          return_rate_next: pct_val(returned_next, current_set.size),
          returned_any_later: returned_any_later,
          return_rate_any_later: pct_val(returned_any_later, current_set.size),
          new_participants: new_set.size,
          new_returned_next: new_returned_next,
          new_return_rate_next: pct_val(new_returned_next, new_set.size),
          veteran_participants: veteran_set.size,
          veteran_returned_next: veteran_returned_next,
          veteran_return_rate_next: pct_val(veteran_returned_next, veteran_set.size)
        }
      end

      yoy_series = [
        { name: "Totale (%)", data: yoy_rows.each_with_object({}) { |r, h| h[r[:year]] = r[:return_rate_next] } },
        { name: "Nuovi iscritti (%)", data: yoy_rows.each_with_object({}) { |r, h| h[r[:year]] = r[:new_return_rate_next] } },
        { name: "Già registrati (%)", data: yoy_rows.each_with_object({}) { |r, h| h[r[:year]] = r[:veteran_return_rate_next] } }
      ]

      photos_by_creator = photo_scope.group(:creator_id).count
      total_unique_creators = editions_count_by_creator.size
      total_photos = photos_by_creator.values.sum
      ed_defs = [
        ["1 sola edizione", 1..1],
        ["2 edizioni", 2..2],
        ["3-4 edizioni", 3..4],
        ["5 o più edizioni", 5..Float::INFINITY]
      ]
      editions_distribution = ed_defs.map do |label, range|
        matched_ids = editions_count_by_creator.select { |_, cnt| range.cover?(cnt) }.keys
        c_cnt = matched_ids.size
        p_cnt = matched_ids.sum { |cid| photos_by_creator[cid].to_i }
        {
          label: label,
          creators: c_cnt,
          creators_pct: pct_val(c_cnt, total_unique_creators),
          photos: p_cnt,
          photos_pct: pct_val(p_cnt, total_photos)
        }
      end

      by_contest = if contest_id.nil?
                     compute_retention_by_contest(ordered_years, creators_by_year_id, creationdates)
                   else
                     []
                   end

      {
        yoy_rows: yoy_rows,
        yoy_series: yoy_series,
        editions_distribution: editions_distribution,
        by_contest: by_contest
      }
    end

    def compute_retention_by_contest(ordered_years, national_creators_by_year_id, creationdates)
      all_triples = Photo.distinct.pluck(:contest_id, :year_id, :creator_id)
      return [] if all_triples.empty?

      contests_by_id = Contest.all.index_by(&:id)
      years_by_id = ordered_years.index_by(&:id)
      global_year_index = {}
      ordered_years.each_with_index { |y, idx| global_year_index[y.id] = idx }

      by_contest_year = {}
      all_triples.each do |cid, yid, cr_id|
        by_contest_year[cid] ||= {}
        by_contest_year[cid][yid] ||= Set.new
        by_contest_year[cid][yid].add(cr_id)
      end

      extra_cids = all_triples.map(&:last).uniq.reject { |cid| creationdates.key?(cid) }
      if extra_cids.any?
        creationdates = creationdates.merge(Creator.where(id: extra_cids).pluck(:id, :creationdate).to_h)
      end

      rows = by_contest_year.filter_map do |cid, year_map|
        contest = contests_by_id[cid]
        next if contest.nil?

        creator_ed_counts = {}
        year_map.each_value do |cset|
          cset.each { |cr_id| creator_ed_counts[cr_id] = (creator_ed_counts[cr_id] || 0) + 1 }
        end
        unique_creators = creator_ed_counts.size
        next if unique_creators == 0

        single_ed = creator_ed_counts.count { |_, cnt| cnt == 1 }
        denom = 0
        same_contest_ret = 0
        national_ret = 0
        new_denom = 0
        new_nat_ret = 0

        year_map.each do |yid, cset|
          idx = global_year_index[yid]
          next_y = idx ? ordered_years[idx + 1] : nil
          next if next_y.nil?

          y_obj = years_by_id[yid]
          next_national_set = national_creators_by_year_id[next_y.id] || Set.new
          next_contest_set = year_map[next_y.id] || Set.new

          denom += cset.size
          same_contest_ret += (cset & next_contest_set).size
          national_ret += (cset & next_national_set).size

          reg_win = y_obj.registration_window_range
          cset.each do |cr_id|
            cd = creationdates[cr_id]
            next unless cd && reg_win.cover?(cd)

            new_denom += 1
            new_nat_ret += 1 if next_national_set.include?(cr_id)
          end
        end

        {
          contest_id: cid,
          contest_name: contest.name,
          editions_count: year_map.size,
          unique_creators: unique_creators,
          single_edition_pct: pct_val(single_ed, unique_creators),
          same_contest_return_rate: denom > 0 ? pct_val(same_contest_ret, denom) : nil,
          national_return_rate: denom > 0 ? pct_val(national_ret, denom) : nil,
          newcomers_return_rate: new_denom > 0 ? pct_val(new_nat_ret, new_denom) : nil
        }
      end

      rows.sort_by { |r| -r[:unique_creators] }
    end

    def compute_nophoto_history(ordered_years, regione)
      records_by_year_id = {}
      Nophoto.where(regione: regione).where.not(year_id: nil).order(:created_at).each do |nop|
        records_by_year_id[nop.year_id] = nop
      end

      rows = ordered_years.filter_map do |y|
        rec = records_by_year_id[y.id]
        next if rec.nil?

        mon = rec.monuments.to_i
        without = rec.count.to_i
        {
          year: y.year,
          monuments: mon,
          without_photo: without,
          with_photo: [mon - without, 0].max,
          without_photo_pct: rec.percent.to_f.round(1)
        }
      end

      {
        rows: rows,
        monuments_series: rows.each_with_object({}) { |r, h| h[r[:year]] = r[:monuments] },
        without_photo_pct_series: rows.each_with_object({}) { |r, h| h[r[:year]] = r[:without_photo_pct] }
      }
    end

    def compute_territory_and_type_trends(ordered_years, photo_scope)
      return nil unless Monument.exists?

      mon_info = {}
      Monument.where.not(wlmid: [nil, ""]).pluck(:wlmid, :normalized_wlmid, :municipality_population, :monument_type).each do |wlmid, norm, pop, mtype|
        is_small = !pop.nil? && pop.to_i < 5000
        info = [is_small, mtype.presence]
        mon_info[wlmid] = info
        mon_info[norm] = info if norm.present?
      end
      return nil if mon_info.empty?

      counts = photo_scope.where.not(wlmid: [nil, ""]).group(:year_id, :wlmid).count
      per_year = {}
      type_totals = {}

      counts.each do |(yid, wlmid), cnt|
        info = mon_info[wlmid] || mon_info[AnalyticsCalculator.normalize_wlmid(wlmid)]
        next if info.nil?

        c = cnt.to_i
        per_year[yid] ||= { known_total: 0, small: 0, types: {} }
        per_year[yid][:known_total] += c
        per_year[yid][:small] += c if info[0]
        if info[1]
          per_year[yid][:types][info[1]] = (per_year[yid][:types][info[1]] || 0) + c
          type_totals[info[1]] = (type_totals[info[1]] || 0) + c
        end
      end

      small_muni_photos_pct_series = {}
      ordered_years.each do |y|
        st = per_year[y.id]
        next if st.nil? || st[:known_total] == 0

        small_muni_photos_pct_series[y.year] = pct_val(st[:small], st[:known_total])
      end

      top_types = type_totals.sort_by { |_, cnt| -cnt }.first(5).map(&:first)
      type_share_series = top_types.map do |t|
        data = {}
        ordered_years.each do |y|
          st = per_year[y.id]
          next if st.nil? || st[:known_total] == 0

          data[y.year] = pct_val(st[:types][t].to_i, st[:known_total])
        end
        { name: t, data: data }
      end

      {
        small_muni_photos_pct_series: small_muni_photos_pct_series,
        type_share_series: type_share_series
      }
    end

    def compute_wlmid_quality(ordered_years, photo_scope)
      has_ref = Monument.exists?
      known_norms = has_ref ? Monument.where.not(normalized_wlmid: [nil, ""]).pluck(:normalized_wlmid).to_set : nil

      rows = ordered_years.filter_map do |y|
        y_scope = photo_scope.where(year_id: y.id)
        total = y_scope.count
        next if total == 0

        missing = y_scope.where(wlmid: [nil, ""]).count
        unknown = if known_norms
                    wlmid_counts = y_scope.where.not(wlmid: [nil, ""]).group(:wlmid).count
                    wlmid_counts.sum { |w, c| known_norms.include?(AnalyticsCalculator.normalize_wlmid(w)) ? 0 : c }
                  else
                    0
                  end

        {
          year: y.year,
          total: total,
          missing: missing,
          missing_pct: pct_val(missing, total),
          unknown: unknown,
          unknown_pct: pct_val(unknown, total)
        }
      end

      {
        rows: rows,
        has_monuments_ref: has_ref
      }
    end

    def compute_seasonality(ordered_years, photo_scope)
      day_names = %w[Domenica Lunedì Martedì Mercoledì Giovedì Venerdì Sabato]
      display_order = [1, 2, 3, 4, 5, 6, 0]
      weekday_sums = Hash.new(0)
      weekend_share_by_year = {}
      phase1_data = {}
      phase2_data = {}
      phase3_data = {}

      ordered_years.each do |y|
        daily = photo_scope.where(year_id: y.id).where.not(photodate: nil).group_by_day(:photodate).count
        next if daily.empty?

        y_total = 0
        weekend_cnt = 0
        p1 = 0
        p2 = 0
        p3 = 0

        daily.each do |day_key, cnt|
          d = day_key.respond_to?(:to_date) ? day_key.to_date : Date.parse(day_key.to_s)
          c = cnt.to_i
          y_total += c
          wday = d.wday
          weekday_sums[wday] += c
          weekend_cnt += c if wday == 0 || wday == 6
          if d.day <= 15
            p1 += c
          elsif d.day <= 27
            p2 += c
          else
            p3 += c
          end
        end

        next if y_total == 0

        weekend_share_by_year[y.year] = pct_val(weekend_cnt, y_total)
        phase1_data[y.year] = pct_val(p1, y_total)
        phase2_data[y.year] = pct_val(p2, y_total)
        phase3_data[y.year] = pct_val(p3, y_total)
      end

      weekday_totals = {}
      display_order.each do |wday|
        weekday_totals[day_names[wday]] = weekday_sums[wday]
      end

      month_phases_series = [
        { name: "Giorni 1-15", data: phase1_data },
        { name: "Giorni 16-27", data: phase2_data },
        { name: "Ultimi 3 giorni (28-30)", data: phase3_data }
      ]

      {
        weekday_totals: weekday_totals,
        weekend_share_by_year: weekend_share_by_year,
        month_phases_series: month_phases_series
      }
    end

    def pct_val(part, total)
      return 0.0 if total.to_i <= 0

      (part.to_f / total.to_f * 100.0).round(1)
    end

    def median_val(values)
      return nil if values.empty?

      sorted = values.sort
      mid = sorted.size / 2
      if sorted.size.odd?
        sorted[mid].round(1)
      else
        ((sorted[mid - 1] + sorted[mid]) / 2.0).round(1)
      end
    end
  end
end
