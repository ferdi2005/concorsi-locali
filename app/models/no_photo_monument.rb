class NoPhotoMonument < ApplicationRecord
  belongs_to :year, optional: true
  belongs_to :photo, optional: true
  validates :item, presence: true, uniqueness: true
end
