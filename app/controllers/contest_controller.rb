class ContestController < ApplicationController
  include ContestHelper
  def index
    @contests = Contest.all.sort_by{ |contest| contest.photos.count }
  end

  def show
    @contest = Contest.find(params[:id])
    @creators = []
    Creator.all.each do |creator|
      if creator.photos.where(contest: @contest).any?
        @creators.push(creator)
      end
    end
    @creators = @creators.sort_by{|gp| gp.photos.where(contest: @contest).count}.reverse
  end

  def upload
    unless @contest = Contest.find_by(id: params[:id])
      redirect_to root_path
      flash[:error] = 'ID NON VALIDO'
    end
  end

  def uploadpost
    @contest = Contest.find_by(id: params[:contest][:id])
    if @contest.update_attributes(params_ok)
      redirect_to root_path
      flash[:success] = 'OK'
    else
      render 'upload'
    end
  end

  def data
    UpdateDataJob.perform_now(false)
    return :ok
  end
  
  def usercount 
    @contest = Contest.find(params[:id])
    count = 0
      Creator.all.each do |creator|
        if creator.photos.where(contest: @contest).any?
          count += 1
        end
      end
      render :json => count
  end
end
private
def params_ok
  params.require(:contest).permit(:logo)
end