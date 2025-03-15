class ContestController < ApplicationController
  include ContestHelper
  http_basic_authenticate_with name: "wikilovesmonuments", password: ENV["SECRET_PASSWORD"], only: [:upload, :uploadpost]

  def index
    @contests = Contest.with_attached_logo.includes(:photos, :contest_years).sort_by{ |contest| contest.contest_years.where(year: @year).first&.count }.reverse
    @nophotograph = {}
    Nophoto.where(regione: nil).each do |nop|
      @nophotograph[nop.created_at] = nop.count
    end

    @nophotographpercent = {}
    Nophoto.where(regione: nil).each do |nop|
      @nophotographpercent[nop.created_at] = nop.percent
    end
    @rank = ContestYear.where(year: @year).sort_by{|c| c.count}.pluck(:id).reverse
  end

  def show
    @contest = Contest.includes(:photos => :creator).find(params[:id])

    @photos = @contest.photos.select { |photo| photo.year == @year }
    @creators = @photos.each(&:creator).uniq
    ## Ordinamento dei creatori

    @creators = @creators.sort_by{|gp| gp.photos.where(contest: @contest).count}.reverse
    @nophotograph = {}
    Nophoto.where(regione: @contest.region, year: @year).each do |nop|
      @nophotograph[nop.created_at] = nop.count
    end

    @nophotographpercent = {}
    Nophoto.where(regione: @contest.region, year: @year).each do |nop|
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
    if @contest.update!(params_ok)
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
