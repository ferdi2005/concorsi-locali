class NoPhotoMonument < ApplicationRecord
  belongs_to :year
  belongs_to :photo
  validates :item, presence: true, uniqueness: true
end
