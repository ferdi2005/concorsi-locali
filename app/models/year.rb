class Year < ApplicationRecord
  has_many :nophotos
  has_many :photos
  has_many :nophoto
  has_many :no_photo_monuments
  has_many :creators
  has_many :contest_years
  has_many :creator_yearly_activities
  has_one :year_analytic, dependent: :destroy

  def period_start_date
    raw = ENV["PERIOD_START"].presence || "1 september"
    Date.parse("#{raw} #{year}")
  end

  def period_end_date
    raw = ENV["PERIOD_END"].presence || "30 september"
    Date.parse("#{raw} #{year}")
  end

  def registration_window_start
    period_start_date - 3.days
  end

  def registration_window_end
    period_end_date
  end

  def registration_window_range
    registration_window_start.beginning_of_day..registration_window_end.end_of_day
  end

  def participating_creators(contest: nil)
    photo_scope = Photo.where(year_id: id)
    photo_scope = photo_scope.where(contest_id: contest.id) if contest
    Creator.where(id: photo_scope.select(:creator_id).distinct)
  end

  def new_creators(contest: nil)
    participating_creators(contest: contest).where(creationdate: registration_window_range)
  end
end
