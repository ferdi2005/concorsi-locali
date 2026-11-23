class CreatorYearlyActivity < ApplicationRecord
  SEGMENTS = %w[
    new_only_wlm
    returning_only_wlm
    occasional
    year_round_100_plus
  ].freeze

  belongs_to :creator
  belongs_to :year

  validates :uploader_segment, inclusion: { in: SEGMENTS }, allow_nil: true
end
