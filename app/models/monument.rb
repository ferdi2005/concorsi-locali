class Monument < ApplicationRecord
  validates :item, presence: true, uniqueness: true

  scope :visible, -> { where(hidden: false) }
  scope :recent, ->(threshold = 1950) { where("inception_year >= ?", threshold) }
  scope :small_municipality, ->(max_pop = 5000) { where("municipality_population IS NOT NULL AND municipality_population < ?", max_pop) }
end
