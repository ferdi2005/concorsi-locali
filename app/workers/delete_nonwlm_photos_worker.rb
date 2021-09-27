class DeleteNonwlmPhotosWorker
  include Sidekiq::Worker

  def perform(*args)
    Photo.all.each do |photo|
      # Verifica che la fotografia sia ancora parte del concorso cercandone i template e trovando quello che identifica una foto partecipante al concorso

      templates = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {:action=>:query, :prop=>:templates, :pageids=> photo.pageid, :tllimit => :max, :format=>:json}).to_h.try(:[], "query").try(:[], "pages").try(:[], photo.pageid.to_s).try(:[], "templates")

      unless templates.try(:any?) { |t| t["title"] == "Template:Monumento italiano" }
        photo.destroy
        if photo.creator.photos.count == 0
          # Se all'autore non sono rimaste fotografie, lo elimino per non lasciarne conto
          photo.creator.destroy
        end
      end
    end
  end
end
