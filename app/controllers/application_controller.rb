class ApplicationController < ActionController::Base
  before_action :year

  def year
    if Date.today.month == 10
      UpdateDataWorker.perform_async
    end

    if params[:year].present? && (requested = Year.find_by(year: params[:year].to_s))
      @year = requested
    elsif (@year = Year.find_by(year: Date.today.year.to_s))
      @year
    else
      @year = Year.order(:year).last
    end
  end
end
