class Photo < ApplicationRecord
  belongs_to :contest
  belongs_to :creator
  validates :pageid, uniqueness: true
end
