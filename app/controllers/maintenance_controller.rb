class MaintenanceController < ApplicationController
  def recent_monuments
    @threshold = params[:threshold].present? ? params[:threshold].to_i : 1950
    @years = Year.order(year: :desc).to_a
    @selected_year_id = params[:year_id].presence

    recent_monuments = Monument.where("inception_year >= ?", @threshold)
    @total_recent_monuments = recent_monuments.count

    monuments_by_wlmid = recent_monuments.where.not(normalized_wlmid: [nil, ""]).index_by(&:normalized_wlmid)
    raw_wlmids = recent_monuments.where.not(wlmid: [nil, ""]).pluck(:wlmid, :normalized_wlmid).flatten.compact.uniq

    if raw_wlmids.any?
      photo_scope = Photo.where(wlmid: raw_wlmids).includes(:creator, :year, :contest).order(photodate: :desc)
      photo_scope = photo_scope.where(year_id: @selected_year_id.to_i) if @selected_year_id
      @total_flagged_photos = photo_scope.count
      @flagged_photos = photo_scope.limit(500).map do |photo|
        norm = AnalyticsCalculator.normalize_wlmid(photo.wlmid)
        mon = monuments_by_wlmid[norm]
        { photo: photo, monument: mon }
      end
    else
      @total_flagged_photos = 0
      @flagged_photos = []
    end
  end
end
