module Toolforge
  class UpdateQualityStatusWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    QUALITY_CATEGORY = "Quality_images".freeze
    FEATURED_CATEGORY = "Featured_pictures_on_Wikimedia_Commons".freeze

    def perform(year_id = nil)
      scope = year_id.present? ? Photo.where(year_id: year_id) : Photo.all
      scope.in_batches(of: 1000) do |batch|
        update_batch(batch)
      end
    end

    private

    def update_batch(batch)
      rows = batch.pluck(:id, :pageid, :quality_image, :featured_picture)
      pageids = rows.filter_map { |_, pid, _, _| pid }.uniq
      return if pageids.empty?

      qi_pageids = WikimediaReplicaClient.fetch_pageids_in_category(pageids, QUALITY_CATEGORY)
      fp_pageids = WikimediaReplicaClient.fetch_pageids_in_category(pageids, FEATURED_CATEGORY)

      qi_true = []
      qi_false = []
      fp_true = []
      fp_false = []

      rows.each do |id, pageid, current_qi, current_fp|
        next if pageid.nil?

        pid = pageid.to_i
        is_qi = qi_pageids.include?(pid)
        is_fp = fp_pageids.include?(pid)

        qi_true << id if is_qi && current_qi != true
        qi_false << id if !is_qi && current_qi != false
        fp_true << id if is_fp && current_fp != true
        fp_false << id if !is_fp && current_fp != false
      end

      now = Time.current
      Photo.where(id: qi_true).update_all(quality_image: true, updated_at: now) if qi_true.any?
      Photo.where(id: qi_false).update_all(quality_image: false, updated_at: now) if qi_false.any?
      Photo.where(id: fp_true).update_all(featured_picture: true, updated_at: now) if fp_true.any?
      Photo.where(id: fp_false).update_all(featured_picture: false, updated_at: now) if fp_false.any?
    end
  end
end
