class ContestYearAnalytic < ApplicationRecord
  belongs_to :contest_year
  belongs_to :top1_creator, class_name: "Creator", optional: true
end
