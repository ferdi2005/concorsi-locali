class ContestController < ApplicationController
  include ContestHelper
  def index
    @contests = Contest.with_attached_logo.includes(:photos).sort_by{ |contest| contest.photos.count }
    @nophotograph = {}
    Nophoto.where(regione: nil).each do |nop|
      @nophotograph[nop.created_at] = nop.count
    end

    @nophotographpercent = {}
    Nophoto.where(regione: nil).each do |nop|
      @nophotographpercent[nop.created_at] = nop.percent
    end
  end

  def show
    @contest = Contest.includes(:photos).find(params[:id])
    @creators = []
    Creator.all.each do |creator|
      if creator.photos.where(contest: @contest).any?
        @creators.push(creator)
      end
    end
    @creators = @creators.sort_by{|gp| gp.photos.where(contest: @contest).count}.reverse
    @nophotograph = {}
    Nophoto.where(regione: @contest.region).each do |nop|
      @nophotograph[nop.created_at] = nop.count
    end

    @nophotographpercent = {}
    Nophoto.where(regione: @contest.region).each do |nop|
      @nophotographpercent[nop.created_at] = nop.percent
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
    if @contest.update_attributes(params_ok)
      redirect_to root_path
      flash[:success] = 'OK'
    else
      render 'upload'
    end
  end
end
private
def params_ok
  params.require(:contest).permit(:logo)
end