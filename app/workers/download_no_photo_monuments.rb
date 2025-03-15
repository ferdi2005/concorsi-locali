class DownloadNoPhotoMonuments
  include Sidekiq::Worker

  def perform(*args)
    @year = Year.find_by(year: DateTime.now.year)
    @no_photo_monuments = []
    HTTParty.get("https://cerca.wikilovesmonuments.it/monuments/nophoto_endpoint.json").each do |monument|
      @no_photo_monuments.push({item: monument[0], wlmid: monument[1], created_at: DateTime.now, updated_at: DateTime.now})
    end
    NoPhotoMonument.upsert_all(@no_photo_monuments, unique_by: :item) unless @no_photo_monuments.empty?
  end
end
