class UpdateGlobalUsageWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })

  def perform(*args)
    puts 'Inizio a cercare le foto che sono state usate su Wiki'
    Photo.all.each do |photo|
      globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php?action=query&prop=globalusage&pageids=#{photo.pageid}&gunamespace=0&format=json", uri_adapter: Addressable::URI).to_a[1][1]['pages'][photo.pageid.to_s]['globalusage'].try(:empty?)
      if !globalusage != photo.usedonwiki
        photo.update_attribute(:usedonwiki, !globalusage)
      end
    end
  end
end
