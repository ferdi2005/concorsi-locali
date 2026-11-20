require "set"

module Toolforge
  class DeleteNonwlmPhotosWorker
    include Sidekiq::Worker

    def perform(*args)
      @year = Year.find_by_year(Date.today.year)
      return if @year.nil?

      Photo.where(year: @year).in_batches(of: 1000) do |batch|
        batch_photos = batch.includes(:creator).to_a
        pageids = batch_photos.filter_map(&:pageid).uniq
        valid_pageids = pageids.empty? ? Set.new : WikimediaReplicaClient.fetch_pageids_with_template(pageids, "Monumento_italiano")

        batch_photos.each do |photo|
          next unless photo.pageid.nil? || !valid_pageids.include?(photo.pageid.to_i)

          creator = photo.creator
          photo.destroy
          if creator && !creator.destroyed? && creator.photos.count == 0
            # Se all'autore non sono rimaste fotografie, lo elimino per non lasciarne conto
            creator.destroy
          end
        end
      end
    end
  end
end
