class Creator < ApplicationRecord
  has_many :photos
  belongs_to :year, optional: :true
  validates :username, presence: true, allow_nil: false, uniqueness: true
  validates :userid, presence: true, uniqueness: true
end
