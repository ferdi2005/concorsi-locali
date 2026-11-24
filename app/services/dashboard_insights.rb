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

      # Modelli di fotocamera più usati nell'edizione più recente con EXIF
      top_models = []
      if latest_year_with_exif
        latest_scope = base.where(year_id: latest_year_with_exif.id)
        latest_total = latest_scope.count
        model_rows = latest_scope
          .where.not(camera_model: [nil, ""])
          .group(:camera_make, :camera_model, :device_category)
          .order(Arel.sql("COUNT(*) DESC"))
          .limit(10)
          .pluck(
            :camera_make,
            :camera_model,
            :device_category,
            Arel.sql("COUNT(*)"),
            Arel.sql("COUNT(DISTINCT creator_id)")
          )

        top_models = model_rows.map do |make, model, dev_cat, cnt, users_cnt|
          cnt_i = cnt.to_i
          {
            make: make,
            model: model,
            device_category: dev_cat,
            photos: cnt_i,
            share: latest_total > 0 ? (cnt_i.to_f / latest_total * 100.0).round(1) : 0.0,
            users: users_cnt.to_i
          }
        end
      end

      {
        by_year: by_year,
        no_exif_by_source: no_exif_by_source,
        top_models: top_models,
        top_models_year: latest_year_with_exif&.year
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
  end
end
