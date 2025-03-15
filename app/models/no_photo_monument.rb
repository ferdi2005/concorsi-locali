class NoPhotoMonument < ApplicationRecord
  belongs_to :year
  belongs_to :photo
end
