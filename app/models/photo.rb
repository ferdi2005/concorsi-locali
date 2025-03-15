class Photo < ApplicationRecord
  belongs_to :contest
  belongs_to :creator
  belongs_to :year
  has_one :no_photo_monument
end
