class ApplicationController < ActionController::Base
  before_action :year

  def year
    if Date.today.month == 10
      UpdateDataWorker.perform_async
    end

    if !cookies[:year_id].blank? && Year.find_by(id: cookies[:year_id].to_i)
      @year = Year.find(cookies[:year_id].to_i)
    elsif (@year = Year.find_by_year(Date.today.year))
      cookies[:year_id] = @year.id
    else
      @year = Year.last
    end
  end

end
