class CreatorsController < ApplicationController
  def show
    unless (@uploader = Creator.find_by(id: params[:id]))
      @uploader = Creator.where('LOWER(username) = ?', params[:id].to_s.downcase).first
    end

    if @uploader.nil?
      raise ActionController::RoutingError.new('Not Found')
    end

    # Riepilogo pluriennale dell'utente
    yearly_rows = Photo
      .where(creator_id: @uploader.id)
      .joins(:year)
      .group("years.id", "years.year")
      .order("years.year DESC")
      .pluck(
        "years.id",
        "years.year",
        Arel.sql("COUNT(photos.id)"),
        Arel.sql("SUM(CASE WHEN photos.usedonwiki = true THEN 1 ELSE 0 END)"),
        Arel.sql("SUM(CASE WHEN photos.new_monument = true THEN 1 ELSE 0 END)"),
        Arel.sql("COUNT(DISTINCT photos.wlmid)")
      )

    activities_by_year = CreatorYearlyActivity.where(creator_id: @uploader.id).index_by(&:year_id)

    @yearly_stats = yearly_rows.map do |year_id, year_str, total, used, new_mon, monuments|
      total_i = total.to_i
      used_i = used.to_i
      {
        year_id: year_id,
        year: year_str,
        photos_count: total_i,
        used_count: used_i,
        used_pct: total_i > 0 ? (used_i.to_f / total_i * 100.0).round(1) : 0.0,
        new_monuments_count: new_mon.to_i,
        monuments_count: monuments.to_i,
        activity: activities_by_year[year_id]
      }
    end

    @selected_year = if params[:year].present?
                       Year.find_by(year: params[:year]) || @year
                     else
                       @year
                     end

    @photos = @selected_year ? @uploader.photos.where(year: @selected_year).includes(:contest).order(:photodate) : []
    @line_chart = @selected_year ? @uploader.photos.where(year: @selected_year).group_by_day(:photodate).count : {}
  end
end
