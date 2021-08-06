class UpdateGlobalUsageWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: :all
  })

  def perform(*args)
    Photo.in_batches(of: 50) do |batch|
      # Cerco le foto usate sui progetti Wikimedia in gruppi di 50
      globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: { :action => :query, :prop => :globalusage, :pageids => batch.pluck(:pageid).join("|"), :gunamespace => 0, gulimit: 50, :format => :json}, uri_adapter: Addressable::URI).to_h["query"]["pages"]
      
      batch.each do |photo|
        # Aggiorna la singola foto sulla base di quanto verificato (invertendo poiché blank a true significa foto non usata)
        photo.update!(usedonwiki: !globalusage[photo.pageid.to_s]["globalusage"].blank?)
      end
    end
  end
end
