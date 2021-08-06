class UpdatePhotosCountWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })

  def perform(*args)
    Contest.all.each do |contest|
      # Richiede le foto della categoria
      commons_url = "https://commons.wikimedia.org/w/api.php"
      request = HTTParty.get(commons_url, query: {action: :query, list: :categorymembers, cmtitle: contest.category, cmlimit: 500, cmdir: :newer, format: :json}, uri_adapter: Addressable::URI).to_h

      photolist = request["query"]["categorymembers"]
      # Procede con la continuazione
      while !request["continue"].nil?
        request = HTTParty.get(commons_url, query: {action: :query, list: :categorymembers, cmtitle: contest.category, cmlimit: 500, cmdir: :newer, cmcontinue: request["continue"]["cmcontinue"], format: :json}, uri_adapter: Addressable::URI).to_h
        
        photolist += request["query"]["categorymembers"] # Somma i due array
      end

      # Rimuove eventuali duplicati
      photolist.uniq!
      
      # Rimuove le pagine che non sono fotografie 
      photolist.reject! { |p| p['ns'] != 6}
      
      # Aggiorna il conto delle fotografie del concorso
      contest.update_attribute(:count, photolist.count)
    end
  end
end
