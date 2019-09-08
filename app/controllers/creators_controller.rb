class CreatorsController < ApplicationController
  def show
    @uploader = Creator.find_by(id: params[:id])
  end
end
