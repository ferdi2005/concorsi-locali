class DownloadNoPhotoMonuments
  include Sidekiq::Worker

  def perform(*args)
    NoPhotoMonument.delete_all
    ActiveRecord::Base.connection.reset_pk_sequence!('no_photo_monuments')
    @no_photo_monuments = []
    HTTParty.get("https://cerca.wikilovesmonuments.it/monuments/nophoto_endpoint.json").each do |monument|
      @no_photo_monuments.push({item: monument[0], wlmid: monument[1], created_at: DateTime.now, updated_at: DateTime.now})
    end
    NoPhotoMonument.insert_all(@no_photo_monuments) unless @no_photo_monuments.empty?
  end
end
