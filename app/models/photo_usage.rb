class PhotoUsage < ApplicationRecord
  belongs_to :photo

  scope :active, -> { where(active: true) }

  def self.project_domain_for_wiki(wiki)
    w = wiki.to_s.strip
    return nil if w.empty?

    if (m = w.match(/\A([a-z0-9_-]+)wiki\z/))
      lang = m[1].tr("_", "-")
      "#{lang}.wikipedia.org"
    elsif (m = w.match(/\A([a-z0-9_-]+)(wikivoyage|wikisource|wiktionary|wikibooks|wikiquote|wikinews|wikiversity)\z/))
      lang = m[1].tr("_", "-")
      "#{lang}.#{m[2]}.org"
    end
  end
end
