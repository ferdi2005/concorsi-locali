class UpdatePhotosCountWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })

  def perform(*args)
    Year.where(storicized: false).each do |year|
      Contest.all.each do |contest|
        # Richiede le foto della categoria
        commons_url = "https://commons.wikimedia.org/w/api.php"
        request = HTTParty.get(commons_url, query: {action: :query, prop: :categoryinfo, titles: contest.cat_name(year), format: :json}, uri_adapter: Addressable::URI).to_h

        photos_count = request["query"]["pages"].first[1]["categoryinfo"]["files"]

        # Procede con le fortificazioni
        commons_url = "https://commons.wikimedia.org/w/api.php"
        request = HTTParty.get(commons_url, query: {action: :query, prop: :categoryinfo, titles: contest.cat_name(year) + year.special_category, format: :json}, uri_adapter: Addressable::URI).to_h

        special_category_count_count = request["query"]["pages"].first[1]["categoryinfo"].try(:[], "files")

        # Aggiorna il conto delle fotografie del concorso
        contest.update!(count: photos_count, special_category_count: special_category_count_count)
      end
    end
  end
end
