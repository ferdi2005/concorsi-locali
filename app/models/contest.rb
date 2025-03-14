class Contest < ApplicationRecord
  has_many :photos
  has_one_attached :logo
  validate :correct_document_mime_type

  def position
    return Contest.all.sort_by{|gp| gp.photos.count}.pluck(:id).reverse.find_index(self.id) + 1
  end

  def cat_name(year_obj)
    return "#{ENV["CAT_PREFIX"]} #{year_obj.year} #{ENV["CAT_SUFFIX"]} - #{self.category}"
  end

  def correct_document_mime_type
    if logo.attached? && !logo.image?
      document.purge # delete the uploaded file
      errors.add(:logo, 'Deve essere una immagine')
    end
  end
end
