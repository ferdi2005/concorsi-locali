module Toolforge
  class UpdateGlobalUsageWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    def perform(*args)
      Photo.in_batches(of: 1000) do |batch|
        update_batch(batch)
      end

      contests = Contest.all.to_a
      Year.all.each do |year|
        update_contest_years(year, contests)
      end
    end

    private

    def update_batch(batch)
      photos = batch.pluck(:id, :pageid, :usedonwiki)
      pageids = photos.filter_map { |_, pageid, _| pageid }.uniq
      return if pageids.empty?

      used_pageids = WikimediaReplicaClient.fetch_globally_used_pageids(pageids)
      used_ids = []
      unused_ids = []

      photos.each do |id, pageid, current_usedonwiki|
        next if pageid.nil?

        # Aggiorna la singola foto solo se lo stato usedonwiki è cambiato
        is_used = used_pageids.key?(pageid.to_s)
        if is_used && current_usedonwiki != true
          used_ids << id
        elsif !is_used && current_usedonwiki != false
          unused_ids << id
        end
      end

      now = Time.current
      Photo.where(id: used_ids).update_all(usedonwiki: true, updated_at: now) if used_ids.any?
      Photo.where(id: unused_ids).update_all(usedonwiki: false, updated_at: now) if unused_ids.any?
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
