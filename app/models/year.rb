class Year < ApplicationRecord
  has_many :nophotos
  has_many :photos
  has_many :nophoto
  has_many :no_photo_monuments
end
