module Toolforge
  class UpdateUploadSourceWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    SOURCE_CATEGORIES = {
      "webapp_mobile" => [
        "Uploaded_with_Wiki_Loves_Monuments_Italia_webapp_(mobile)",
        "Uploaded_with_WLM_Italia_mobile"
      ],
      "webapp" => [
        "Uploaded_with_Wiki_Loves_Monuments_Italia_webapp",
        "Uploaded_via_Wiki_Loves_Monuments_Italia_webapp",
        "Files_uploaded_by_Wiki_Loves_Monuments_Italia_webapp"
      ],
      "upload_wizard" => [
        "Uploaded_with_UploadWizard",
        "Uploaded_via_Campaign:wlm-it"
      ]
    }.freeze

    def perform(year_id = nil)
      scope = year_id.present? ? Photo.where(year_id: year_id) : Photo.all
      scope.where(upload_source: [nil, ""]).in_batches(of: 1000) do |batch|
        update_batch(batch)
      end
    end

    private

    def update_batch(batch)
      rows = batch.pluck(:id, :pageid)
      pageids = rows.filter_map { |_, pid| pid }.uniq
      return if pageids.empty?

      source_by_pageid = {}
      SOURCE_CATEGORIES.each do |source_key, categories|
        categories.each do |cat|
          matched = WikimediaReplicaClient.fetch_pageids_in_category(pageids, cat)
          matched.each { |pid| source_by_pageid[pid] ||= source_key }
        end
      end

      grouped_ids = Hash.new { |h, k| h[k] = [] }
      rows.each do |id, pageid|
        next if pageid.nil?

        src = source_by_pageid[pageid.to_i] || "other"
        grouped_ids[src] << id
      end

      now = Time.current
      grouped_ids.each do |source_key, ids|
        Photo.where(id: ids).update_all(upload_source: source_key, updated_at: now) if ids.any?
      end
    end
  end
end
