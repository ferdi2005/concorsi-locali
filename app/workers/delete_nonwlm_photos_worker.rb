class DeleteNonwlmPhotosWorker
  include Sidekiq::Worker

  def perform(*args)
    Photo.all.each do |photo|
      templates = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: {:action=>:query, :prop=>:templates, :pageids=> photo.pageid, :tllimit => :max, :format=>:json}).to_a[1][1]["pages"].first[1]["templates"]
      
      unless templates.nil?
        templates.each do |template|
          if template["title"] == "Template:Monumento italiano"
            @monumentoitaliano = true
            puts "Foto #{photo.name} esaminata e ancora attiva"
          end
        end
      end
      
      unless @monumentoitaliano == true
        puts "Foto #{photo.name} cancellata"
        photo.destroy
        if photo.creator.photos.count == 1
          puts "Autore #{photo.creator.name} cancellato"
          photo.creator.destroy
        end
      end
    end
  end
end
