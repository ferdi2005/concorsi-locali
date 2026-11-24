class HistoryController < ApplicationController
  def index
    @years = Year.includes(:year_analytic).order(:year).to_a
    @years_by_id = @years.index_by(&:id)
    @analytics_by_year_id = @years.each_with_object({}) { |y, h| h[y.id] = y.year_analytic }
    @latest_year = @years.last

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

    # Grafico riuso per fascia di foto per monumento (ultima edizione con analytics)
    latest_with_reuse = @years.reverse.find { |y| y.year_analytic&.reuse_by_monument_bucket&.dig("buckets").present? }
    @reuse_chart_year = latest_with_reuse&.year
    @reuse_bucket_chart = if latest_with_reuse
                            buckets = latest_with_reuse.year_analytic.reuse_by_monument_bucket["buckets"]
                            AnalyticsCalculator::BUCKET_LABELS.each_with_object({}) do |(key, label), h|
                              h[label] = buckets.dig(key, "rate") || 0.0
                            end
                          else
                            {}
                          end

    # Top monumenti più fotografati dell'ultima edizione
    @top_monuments = DashboardInsights.top_monuments(year: @latest_year, limit: 15)

    # Temi
    @special_years = @years.select(&:special?)

    # Top uploader pluriennali (in cache)
    @top_uploaders = Rails.cache.fetch("dashboard_insights:v#{DashboardInsights.cache_version}:top_uploaders", expires_in: DashboardInsights::CACHE_TTL) do
      AnalyticsCalculator.top_uploaders_across_years(limit: 50)
    end

    # Territorio: matrice anni x regioni
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

    # Fase 2: attività fuori settembre, canale e qualità
    load_phase2_data

    # Fase 3: anagrafica monumenti (cerca), EXIF e pageviews (in cache via DashboardInsights)
    load_phase3_data
  end

  private

  def load_phase3_data
    @monuments_coverage = DashboardInsights.monuments_coverage
    @has_monuments_data = @monuments_coverage.present?
    if @has_monuments_data
      @monument_sentinels = @monuments_coverage[:sentinels]
      @small_municipalities = @monuments_coverage[:small_municipalities]
      @monument_types_stats = @monuments_coverage[:types_stats]
      @monument_types_chart = @monument_types_stats.first(12).each_with_object({}) do |row, h|
        h[row[:type]] = row[:no_photo_pct]
      end
    end

    @exif_summary = DashboardInsights.exif_summary(years: @years)
    @has_exif_data = @exif_summary.present?
    if @has_exif_data
      @exif_by_year = @exif_summary[:by_year]
      @exif_no_exif_by_source = @exif_summary[:no_exif_by_source]
      @exif_top_models = @exif_summary[:top_models]
      @exif_top_models_year = @exif_summary[:top_models_year]
      @exif_device_chart = [
        {
          name: "Smartphone (% foto)",
          data: @years.each_with_object({}) { |y, h| h[y.year] = @exif_by_year.dig(y.id, :smartphone_pct) if @exif_by_year[y.id] }
        },
        {
          name: "Smartphone (% utenti)",
          data: @years.each_with_object({}) { |y, h| h[y.year] = @exif_by_year.dig(y.id, :smartphone_users_pct) if @exif_by_year[y.id] }
        },
        {
          name: "Fotocamera (% foto)",
          data: @years.each_with_object({}) { |y, h| h[y.year] = @exif_by_year.dig(y.id, :camera_pct) if @exif_by_year[y.id] }
        }
      ]
    end

    @pageviews_summary = DashboardInsights.pageviews_summary(years: @years)
    @has_pageviews_data = @pageviews_summary.present?
    if @has_pageviews_data
      @pageviews_by_year = @pageviews_summary[:by_year]
      @top_viewed_pages = @pageviews_summary[:top_pages]
    end
  end

  def load_phase2_data
    cached = Rails.cache.fetch("dashboard_insights:v#{DashboardInsights.cache_version}:phase2:#{@years.map(&:id).join('-')}", expires_in: DashboardInsights::CACHE_TTL) do
      has_activity = CreatorYearlyActivity.exists?
      activity_by_year = {}
      retention_by_year = {}

      if has_activity
        activity_by_year = CreatorYearlyActivity.group(:year_id, :uploader_segment).pluck(
          :year_id,
          :uploader_segment,
          Arel.sql("COUNT(*)"),
          Arel.sql("SUM(wlm_uploads_count)")
        ).each_with_object(Hash.new { |h, k| h[k] = {} }) do |(yid, seg, cnt, photos_sum), acc|
          acc[yid][seg] = { creators: cnt.to_i, photos: photos_sum.to_i }
        end

        @years.each do |year|
          rows = CreatorYearlyActivity.where(year_id: year.id).where.not(post_contest_edits_3m: nil)
          next if rows.empty?

          new_ids = year.new_creators.pluck(:id)
          new_rows = rows.where(creator_id: new_ids)
          ret_rows = rows.where.not(creator_id: new_ids)

          retention_by_year[year.id] = {
            new_total: new_rows.count,
            new_active_3m: new_rows.where("post_contest_edits_3m > 0").count,
            new_active_3m_plus_months: new_rows.where("active_months_after_12m >= 3").count,
            returning_total: ret_rows.count,
            returning_active_3m: ret_rows.where("post_contest_edits_3m > 0").count
          }
        end
      end

      upload_source_counts = Photo.where.not(upload_source: [nil, ""]).group(:year_id, :upload_source).count
      has_upload_source = upload_source_counts.any?
      upload_source_series = if has_upload_source
                               sources = upload_source_counts.keys.map(&:last).uniq.sort
                               sources.map do |src|
                                 {
                                   name: src,
                                   data: @years.each_with_object({}) { |y, h| h[y.year] = upload_source_counts[[y.id, src]] || 0 }
                                 }
                               end
                             else
                               []
                             end

      qi_counts = Photo.where(quality_image: true).group(:year_id).count
      fp_counts = Photo.where(featured_picture: true).group(:year_id).count
      has_quality = qi_counts.any? || fp_counts.any?
      quality_series = if has_quality
                         [
                           {
                             name: "Foto di qualità (QI)",
                             data: @years.each_with_object({}) { |y, h| h[y.year] = qi_counts[y.id] || 0 }
                           },
                           {
                             name: "Foto in vetrina (FP)",
                             data: @years.each_with_object({}) { |y, h| h[y.year] = fp_counts[y.id] || 0 }
                           }
                         ]
                       else
                         []
                       end

      {
        has_activity: has_activity,
        activity_by_year: activity_by_year,
        retention_by_year: retention_by_year,
        has_upload_source: has_upload_source,
        upload_source_series: upload_source_series,
        has_quality: has_quality,
        quality_series: quality_series
      }
    end

    @has_activity_data = cached[:has_activity]
    @activity_by_year = cached[:activity_by_year]
    @retention_by_year = cached[:retention_by_year]
    @has_upload_source_data = cached[:has_upload_source]
    @upload_source_series = cached[:upload_source_series]
    @has_quality_data = cached[:has_quality]
    @quality_series = cached[:quality_series]
  end
end
