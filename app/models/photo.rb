class Photo < ApplicationRecord
  belongs_to :contest
  belongs_to :creator
end
