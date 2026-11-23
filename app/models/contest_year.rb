class ContestYear < ApplicationRecord
  belongs_to :contest
  belongs_to :year
  has_one :contest_year_analytic, dependent: :destroy
end
