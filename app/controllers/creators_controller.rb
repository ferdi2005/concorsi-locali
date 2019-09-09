class CreatorsController < ApplicationController
  def show
    unless @uploader = Creator.find_by(id: params[:id])
      @uploader = Creator.where('LOWER(username) = ?', params[:id].to_s.downcase).includes(:photos).first
    end

    if @uploader.nil?
      raise ActionController::RoutingError.new('Not Found')
    end
  end
end
