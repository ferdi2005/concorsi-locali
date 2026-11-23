class WikiPageMonthlyView < ApplicationRecord
  validates :wiki, :page_title, :year_month, presence: true
end
