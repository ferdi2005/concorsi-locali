class Creator < ApplicationRecord
  has_many :photos
  validates :username, presence: true, allow_nil: false, uniqueness: true
  validates :userid, presence: true, uniqueness: true
end
