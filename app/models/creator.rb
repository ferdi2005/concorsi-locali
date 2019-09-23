class Creator < ApplicationRecord
  has_many :photos
  validates :username, presence: true  
end
