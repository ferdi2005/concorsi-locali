class HistoryController < ApplicationController
  def index
    @years = Year.includes(:year_analytic).order(:year).to_a
    @years_by_id = @years.index_by(&:id)
    @analytics_by_year_id = @years.each_with_object({}) { |y, h| h[y.id] = y.year_analytic }

    # Serie partecipanti nuovi e già registrati
    @participants_series = [
      {
        name: "Nuovi iscritti",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.new_creators_count || 0 }
      },
      {
        name: "Già registrati",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.returning_creators_count || 0 }
      }
    ]

    # Foto totali vs senza primi 10
    @photos_series = [
      {
        name: "Foto totali",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.total || y.photos.count }
      },
      {
        name: "Foto senza i primi 10",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.photos_without_top10 || 0 }
      }
    ]

    # Quota primi 10 e ultimi 3 giorni
    @top10_share_series = @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.top10_photos_share || 0.0 }
    @last3_days_series = @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.last_3_days_photos_share || 0.0 }

    # Utenti per il 50% e 90% delle foto
    @concentration_users_series = [
      {
        name: "Utenti per il 50% delle foto",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.creators_for_50_percent || 0 }
      },
      {
        name: "Utenti per il 90% delle foto",
        data: @years.each_with_object({}) { |y, h| h[y.year] = y.year_analytic&.creators_for_90_percent || 0 }
      }
    ]

    # Temi
    @special_years = @years.select(&:special?)

    # Top uploader pluriennali
    @top_uploaders = AnalyticsCalculator.top_uploaders_across_years(limit: 50)

    # Territorio: concorsi regionali per l'anno più recente con dati e serie storica
    @contests = Contest.order(:name).to_a
    @contest_years_matrix = ContestYear
      .includes(:year, :contest, contest_year_analytic: :top1_creator)
      .to_a
      .group_by(&:contest_id)

    # Simulatore di regole di esclusione
    @sim_max_photos = params[:sim_max_photos].present? ? params[:sim_max_photos].to_i : 10
    @sim_exclude_top = params[:sim_exclude_top].present? ? params[:sim_exclude_top].to_i : 0
    @sim_year_id = params[:sim_year_id].presence
    if params[:simulate].present?
      year_ids = @sim_year_id ? [@sim_year_id.to_i] : nil
      @simulation_results = AnalyticsCalculator.simulate(
        year_ids: year_ids,
        max_existing_monument_photos: @sim_max_photos,
        exclude_top_creators: @sim_exclude_top
      )
    end

    # Fase 2: attività fuori settembre e retention (se popolati)
    load_phase2_data

    # Fase 3: anagrafica monumenti (cerca), EXIF e pageviews (se popolati)
    load_phase3_data
  end

  private

  def load_phase3_data
    @has_monuments_data = Monument.exists?
    if @has_monuments_data
      total_m = Monument.count
      no_photo_m = Monument.where(photos_count: 0).count
      with_photo_m = total_m - no_photo_m

      @monument_sentinels = {
        total: total_m,
        without_photo: no_photo_m,
        without_wikipedia: Monument.where(has_wikipedia: false).count,
        without_commons: Monument.where(has_commons_category: false).count,
        with_wlm_without_commons: Monument.where("photos_count > 0").where(has_commons_category: false).count,
        with_wlm_without_p18: Monument.where("photos_count > 0").where(has_p18: false).count,
        with_mic_catalog: Monument.where.not(mic_catalog_id: [nil, ""]).count,
        recent_since_1950: Monument.where("inception_year >= ?", 1950).count,
        with_photo_total: with_photo_m
      }

      # Copertura per fascia comuni (sotto 5.000 abitanti) e comuni mai toccati
      small_scope = Monument.small_municipality(5000)
      @small_municipalities = {
        total_monuments: small_scope.count,
        no_photo_monuments: small_scope.where(photos_count: 0).count,
        untouched_municipalities: Monument.where.not(city_item: [nil, ""]).group(:city_item).having("SUM(photos_count) = 0").count.size,
        total_municipalities: Monument.where.not(city_item: [nil, ""]).distinct.count(:city_item)
      }

      # Copertura per tipologia P31
      type_rows = Monument.group(:monument_type).pluck(
        :monument_type,
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(CASE WHEN photos_count = 0 THEN 1 ELSE 0 END)")
      )
      @monument_types_stats = type_rows.map do |mtype, tot, noph|
        tot_i = tot.to_i
        noph_i = noph.to_i
        {
          type: mtype.presence || "altro / non classificato",
          total: tot_i,
          no_photo: noph_i,
          no_photo_pct: tot_i > 0 ? (noph_i.to_f / tot_i * 100.0).round(1) : 0.0
        }
      end.sort_by { |r| -r[:total] }
    end

    @has_exif_data = Photo.where.not(exif_checked_at: nil).exists?
    if @has_exif_data
      @exif_by_year = @years.each_with_object({}) do |year, acc|
        scope = Photo.where(year_id: year.id).where.not(exif_checked_at: nil)
        checked = scope.count
        next if checked == 0

        year_start = Time.utc(year.year.to_i, 1, 1)
        prev_year_start = Time.utc(year.year.to_i - 1, 1, 1)
        archive_before_year = scope.where("taken_at IS NOT NULL AND taken_at < ?", year_start).count
        archive_before_prev = scope.where("taken_at IS NOT NULL AND taken_at < ?", prev_year_start).count
        smartphone = scope.where(device_category: "smartphone").count
        camera = scope.where(device_category: "camera").count
        no_exif = scope.where(has_exif: false).count

        acc[year.id] = {
          checked: checked,
          archive_pct: (archive_before_year.to_f / checked * 100.0).round(1),
          archive_prev_pct: (archive_before_prev.to_f / checked * 100.0).round(1),
          smartphone_pct: (smartphone.to_f / checked * 100.0).round(1),
          camera_pct: (camera.to_f / checked * 100.0).round(1),
          no_exif_pct: (no_exif.to_f / checked * 100.0).round(1)
        }
      end
    end

    @has_pageviews_data = PhotoUsage.active.exists?
    if @has_pageviews_data
      views_by_page = WikiPageMonthlyView.group(:wiki, :page_title).sum(:views)
      @pageviews_by_year = @years.each_with_object({}) do |year, acc|
        usages = PhotoUsage.active.joins(:photo).where(photos: { year_id: year.id }).distinct.pluck(:wiki, :page_title)
        next if usages.empty?

        langs = usages.map(&:first).uniq.size
        page_views = usages.map { |pair| views_by_page[pair].to_i }.sort.reverse
        total_views = page_views.sum
        top12_views = page_views.first(12).sum

        acc[year.id] = {
          pages_count: usages.size,
          wikis_count: langs,
          total_views: total_views,
          top12_share: total_views > 0 ? (top12_views.to_f / total_views * 100.0).round(1) : 0.0
        }
      end
    end
  end

  def load_phase2_data
    @has_activity_data = CreatorYearlyActivity.exists?
    if @has_activity_data
      @activity_by_year = CreatorYearlyActivity.group(:year_id, :uploader_segment).pluck(
        :year_id,
        :uploader_segment,
        Arel.sql("COUNT(*)"),
        Arel.sql("SUM(wlm_uploads_count)")
      ).each_with_object(Hash.new { |h, k| h[k] = {} }) do |(yid, seg, cnt, photos_sum), acc|
        acc[yid][seg] = { creators: cnt.to_i, photos: photos_sum.to_i }
      end

      @retention_by_year = {}
      @years.each do |year|
        rows = CreatorYearlyActivity.where(year_id: year.id).where.not(post_contest_edits_3m: nil)
        next if rows.empty?

        new_ids = year.new_creators.pluck(:id)
        new_rows = rows.where(creator_id: new_ids)
        ret_rows = rows.where.not(creator_id: new_ids)

        @retention_by_year[year.id] = {
          new_total: new_rows.count,
          new_active_3m: new_rows.where("post_contest_edits_3m > 0").count,
          new_active_3m_plus_months: new_rows.where("active_months_after_12m >= 3").count,
          returning_total: ret_rows.count,
          returning_active_3m: ret_rows.where("post_contest_edits_3m > 0").count
        }
      end
    end

    upload_source_counts = Photo.where.not(upload_source: [nil, ""]).group(:year_id, :upload_source).count
    @has_upload_source_data = upload_source_counts.any?
    if @has_upload_source_data
      sources = upload_source_counts.keys.map(&:last).uniq.sort
      @upload_source_series = sources.map do |src|
        {
          name: src,
          data: @years.each_with_object({}) { |y, h| h[y.year] = upload_source_counts[[y.id, src]] || 0 }
        }
      end
    end

    qi_counts = Photo.where(quality_image: true).group(:year_id).count
    fp_counts = Photo.where(featured_picture: true).group(:year_id).count
    @has_quality_data = qi_counts.any? || fp_counts.any?
    if @has_quality_data
      @quality_series = [
        {
          name: "Foto di qualità (QI)",
          data: @years.each_with_object({}) { |y, h| h[y.year] = qi_counts[y.id] || 0 }
        },
        {
          name: "Foto in vetrina (FP)",
          data: @years.each_with_object({}) { |y, h| h[y.year] = fp_counts[y.id] || 0 }
        }
      ]
    end
  end
end
