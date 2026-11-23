module Toolforge
  class UpdateGlobalUsageWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    def perform(sync_usages = true)
      Photo.in_batches(of: 1000) do |batch|
        update_batch(batch, sync_usages: sync_usages)
      end

      contests = Contest.all.to_a
      Year.all.each do |year|
        update_contest_years(year, contests)
      end
    end

    private

    def update_batch(batch, sync_usages: true)
      photos = batch.pluck(:id, :pageid, :usedonwiki)
      pageids = photos.filter_map { |_, pageid, _| pageid }.uniq
      return if pageids.empty?

      usages_by_pageid = WikimediaReplicaClient.fetch_global_usages_for_pageids(pageids)
      used_ids = []
      unused_ids = []
      now = Time.current
      usage_records = []
      photo_ids_in_batch = []

      photos.each do |id, pageid, current_usedonwiki|
        next if pageid.nil?

        photo_ids_in_batch << id
        page_usages = usages_by_pageid[pageid.to_i] || []
        is_used = page_usages.any?

        if is_used && current_usedonwiki != true
          used_ids << id
        elsif !is_used && current_usedonwiki != false
          unused_ids << id
        end

        next unless sync_usages && is_used

        page_usages.each do |u|
          usage_records << {
            photo_id: id,
            wiki: u[:wiki],
            page_title: u[:page_title],
            active: true,
            created_at: now,
            updated_at: now
          }
        end
      end

      Photo.where(id: used_ids).update_all(usedonwiki: true, updated_at: now) if used_ids.any?
      Photo.where(id: unused_ids).update_all(usedonwiki: false, updated_at: now) if unused_ids.any?

      return unless sync_usages && photo_ids_in_batch.any?

      PhotoUsage.where(photo_id: photo_ids_in_batch, active: true).update_all(active: false, updated_at: now)
      return if usage_records.empty?

      usage_records.each_slice(1000) do |slice|
        if PhotoUsage.connection.supports_insert_conflict_target?
          PhotoUsage.upsert_all(slice, unique_by: :index_photo_usages_uniqueness)
        else
          PhotoUsage.upsert_all(slice)
        end
      end
    end

    def update_contest_years(year, contests)
      contests.each do |contest|
        contestyear = ContestYear.find_by(contest: contest, year: year)
        next if contestyear.nil?

        usedonwiki_count = Photo.where(contest: contest, year: year, usedonwiki: true).count
        usedonwiki_percentage = contestyear.count.to_i > 0 ? (usedonwiki_count.to_f / contestyear.count.to_f * 100) : 0
        contestyear.update!(usedonwiki: usedonwiki_count, usedonwiki_percentage: usedonwiki_percentage)
      end
    end
  end
end
