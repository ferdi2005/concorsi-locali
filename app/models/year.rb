class Year < ApplicationRecord
  has_many :nophotos
  has_many :photos
end
