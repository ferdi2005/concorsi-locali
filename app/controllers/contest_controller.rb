class ContestController < ApplicationController
  include ContestHelper
  http_basic_authenticate_with name: "wikilovesmonuments", password: ENV["SECRET_PASSWORD"], only: [:upload, :uploadpost]

  def index
    @available_years = Year.order(year: :desc).to_a
    @year ||= @available_years.first

    contest_years = @year ? ContestYear.where(year: @year).includes(contest_year_analytic: :top1_creator).index_by(&:contest_id) : {}
    @contest_years_by_contest_id = contest_years

    @contests = Contest.with_attached_logo.to_a.sort_by { |contest|
      contest_years[contest.id]&.count.to_i
    }.reverse

    @year_analytic = @year&.year_analytic
    @prev_year = @year ? @available_years.find { |y| y.year.to_i < @year.year.to_i } : nil
    @prev_year_analytic = @prev_year&.year_analytic
    if @prev_year
      prev_photos = Photo.where(year: @prev_year)
      @prev_national_photos_count = @prev_year.total.to_i > 0 ? @prev_year.total.to_i : prev_photos.count
      @prev_national_creators_count = @prev_year.creators_count.to_i > 0 ? @prev_year.creators_count.to_i : prev_photos.distinct.count(:creator_id)
      @prev_national_depicted_monuments = @prev_year.depicted_monuments.to_i > 0 ? @prev_year.depicted_monuments.to_i : prev_photos.where.not(wlmid: [nil, ""]).distinct.count(:wlmid)
    end

    if @year
      year_photos = Photo.where(year: @year)
      @national_photos_count = @year.total.to_i > 0 ? @year.total.to_i : year_photos.count
      @national_used_photos = year_photos.where(usedonwiki: true).count
      @national_used_pct = @national_photos_count > 0 ? (@national_used_photos.to_f / @national_photos_count * 100.0).round(1) : 0.0
      @national_creators_count = @year.creators_count.to_i > 0 ? @year.creators_count.to_i : year_photos.distinct.count(:creator_id)
      @national_depicted_monuments = @year.depicted_monuments.to_i > 0 ? @year.depicted_monuments.to_i : year_photos.where.not(wlmid: [nil, ""]).distinct.count(:wlmid)
      @national_new_monuments = @year.new_monuments.to_i > 0 ? @year.new_monuments.to_i : year_photos.where(new_monument: true).count
      @national_qi_count = year_photos.where(quality_image: true).count
      @national_fp_count = year_photos.where(featured_picture: true).count
      @daily_photos = year_photos.group_by_day(:photodate).count
    else
      @national_photos_count = 0
      @national_used_photos = 0
      @national_used_pct = 0.0
      @national_creators_count = 0
      @national_depicted_monuments = 0
      @national_new_monuments = 0
      @national_qi_count = 0
      @national_fp_count = 0
      @daily_photos = {}
    end

    @nophotos_for_year = @year ? Nophoto.where(regione: nil, year: @year).order(:created_at).to_a : []
    @nophotograph = @nophotos_for_year.each_with_object({}) { |nop, h| h[nop.created_at] = nop.count }
    @nophotographpercent = @nophotos_for_year.each_with_object({}) { |nop, h| h[nop.created_at] = nop.percent }
    @last_nophoto = @nophotos_for_year.last
    @first_nophoto = @nophotos_for_year.first

    @rank = @year ? ContestYear.where(year: @year).order(count: :desc).pluck(:id) : []
  end

  def show
    @contest = Contest.find(params[:id])

    @contest_years_history = ContestYear
      .where(contest: @contest)
      .includes(:year, contest_year_analytic: :top1_creator)
      .to_a
      .sort_by { |cy| cy.year.year.to_i }

    @available_years = @contest_years_history.map(&:year).reverse

    @selected_year = if params[:year].present?
                       Year.find_by(year: params[:year]) || @year
                     else
                       @year
                     end
    @selected_year ||= @available_years.first

    @contestyear = @selected_year ? ContestYear.find_by(contest: @contest, year: @selected_year) : nil
    @contestyear_analytic = @contestyear&.contest_year_analytic

    # Serie pluriennali per la vista globale del concorso
    @history_photos_series = @contest_years_history.each_with_object({}) { |cy, h| h[cy.year.year] = cy.count.to_i }
    @history_creators_series = @contest_years_history.each_with_object({}) { |cy, h| h[cy.year.year] = cy.creators.to_i }
    @history_top1_share_series = @contest_years_history.each_with_object({}) { |cy, h| h[cy.year.year] = cy.contest_year_analytic&.top1_photos_share || 0.0 }

    # Approfondimenti regionali (in cache via DashboardInsights)
    history_years = @contest_years_history.map(&:year)
    @regional_monuments_coverage = @contest.region.present? ? DashboardInsights.monuments_coverage(regione: @contest.region, contest_id: @contest.id) : nil
    @regional_exif = DashboardInsights.exif_summary(years: history_years, contest_id: @contest.id)
    @regional_pageviews = DashboardInsights.pageviews_summary(years: history_years, contest_id: @contest.id)
    @regional_top_monuments = @selected_year ? DashboardInsights.top_monuments(year: @selected_year, contest_id: @contest.id, limit: 15) : []

    # Dettaglio per l'anno selezionato (query aggregata senza N+1)
    if @selected_year
      photos_scope = Photo.where(contest: @contest, year: @selected_year)
      @daily_photos = photos_scope.group_by_day(:photodate).count

      reg_window = @selected_year.registration_window_range
      rows = photos_scope
        .joins(:creator)
        .group("creators.id", "creators.username", "creators.creationdate")
        .order(Arel.sql("COUNT(photos.id) DESC"))
        .pluck(
          "creators.id",
          "creators.username",
          "creators.creationdate",
          Arel.sql("COUNT(photos.id)"),
          Arel.sql("SUM(CASE WHEN photos.usedonwiki = true THEN 1 ELSE 0 END)"),
          Arel.sql("SUM(CASE WHEN photos.new_monument = true THEN 1 ELSE 0 END)")
        )

      @creator_rows = rows.map do |id, username, creationdate, total, used, new_mon|
        total_i = total.to_i
        used_i = used.to_i
        new_mon_i = new_mon.to_i
        {
          id: id,
          username: username,
          creationdate: creationdate,
          is_new: !creationdate.nil? && reg_window.cover?(creationdate),
          photos_count: total_i,
          used_count: used_i,
          used_pct: total_i > 0 ? (used_i.to_f / total_i * 100.0).round(1) : 0.0,
          new_monument_count: new_mon_i,
          new_monument_pct: total_i > 0 ? (new_mon_i.to_f / total_i * 100.0).round(1) : 0.0
        }
      end

      @new_creators_daily = @selected_year.new_creators(contest: @contest).group_by_day(:creationdate).count

      @nophotos_for_year = @contest.region.present? ? Nophoto.where(regione: @contest.region, year: @selected_year).order(:created_at).to_a : []
      @nophotograph = @nophotos_for_year.each_with_object({}) { |nop, h| h[nop.created_at] = nop.count }
      @nophotographpercent = @nophotos_for_year.each_with_object({}) { |nop, h| h[nop.created_at] = nop.percent }
      @last_nophoto = @nophotos_for_year.last
      @first_nophoto = @nophotos_for_year.first
    else
      @daily_photos = {}
      @creator_rows = []
      @new_creators_daily = {}
      @nophotos_for_year = []
      @nophotograph = {}
      @nophotographpercent = {}
    end
  end

  def upload
    unless (@contest = Contest.find_by(id: params[:id]))
      redirect_to root_path
      flash[:error] = 'ID NON VALIDO'
    end
  end

  def uploadpost
    @contest = Contest.find_by(id: params[:contest][:id])
    if @contest.update!(params_ok)
      redirect_to root_path
      flash[:success] = 'OK'
    else
      render 'upload'
    end
  end

  private

  def params_ok
    params.require(:contest).permit(:logo)
  end
end
