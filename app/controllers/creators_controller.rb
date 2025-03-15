class CreatorsController < ApplicationController
  def show
    unless (@uploader = Creator.find_by(id: params[:id]))
      @uploader = Creator.where('LOWER(username) = ?', params[:id].to_s.downcase).includes(:photos).first
    end

    if @uploader.nil?
      raise ActionController::RoutingError.new('Not Found')
    end

    @photos = @uploader.photos.select { |p| p.year == @year }
    @line_chart = @photos.group_by_day(:photodate).count
  end
end
