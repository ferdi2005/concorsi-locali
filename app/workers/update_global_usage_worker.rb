class UpdateGlobalUsageWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: :all
  })

  def perform(*args)
    array_update = {}
    Photo.in_batches(of: 50) do |batch|
      # Cerco le foto usate sui progetti Wikimedia in gruppi di 50
      globalusage = HTTParty.get("https://commons.wikimedia.org/w/api.php", query: { :action => :query, :prop => :globalusage, :pageids => batch.pluck(:pageid).join("|"), :gunamespace => 0, gulimit: 50, :format => :json}, uri_adapter: Addressable::URI).to_h["query"]["pages"]

      batch.each do |photo|
        # Aggiorna la singola foto sulla base di quanto verificato (invertendo poiché blank a true significa foto non usata)
        array_update[photo.id] = {"usedonwiki": !globalusage[photo.pageid.to_s]["globalusage"].blank?}
      end
    end
    Photo.update(array_update.keys, array_update.values)

    Year.where(storicized: false).each do |year|
      Contest.all.each do |contest|
        usedonwiki_count = Photo.where(contest: contest, year: year, usedonwiki: true).count
        usedonwiki_count != 0 ? usedonwiki_percentage = usedonwiki_count / contestyear.count.to_f * 100 : usedonwiki_percentage = 0
        contestyear.update!(usedonwiki: usedonwiki_count, usedonwiki_percentage: usedonwiki_percentage)
      end
    end
  end
end
