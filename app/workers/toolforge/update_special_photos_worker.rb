module Toolforge
  class UpdateSpecialPhotosWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    def perform(year_id = nil)
      years = year_id.present? ? Year.where(id: year_id, special: true) : Year.where(special: true).order(:year)
      contests = Contest.all.to_a
      now = Time.current

      years.each do |year|
        next if year.special_category.blank?

        contests.each do |contest|
          cat_title = "#{contest.cat_name(year)} #{year.special_category.to_s.strip}"
          special_titles = WikimediaReplicaClient.fetch_category_member_titles(cat_title)

          scope = Photo.where(year_id: year.id, contest_id: contest.id)
          if special_titles.empty?
            scope.where(special: true).update_all(special: false, updated_at: now)
          else
            matched_ids = []
            unmatched_ids = []
            scope.pluck(:id, :name, :special).each do |id, name, current_special|
              is_special = special_titles.include?(name)
              if is_special && current_special != true
                matched_ids << id
              elsif !is_special && current_special != false
                unmatched_ids << id
              end
            end

            matched_ids.each_slice(1000) do |slice|
              Photo.where(id: slice).update_all(special: true, updated_at: now)
            end
            unmatched_ids.each_slice(1000) do |slice|
              Photo.where(id: slice).update_all(special: false, updated_at: now)
            end
          end

          contest_year = ContestYear.find_by(contest_id: contest.id, year_id: year.id)
          next if contest_year.nil?

          special_depicted = scope.where(special: true).where.not(wlmid: [nil, ""]).distinct.count(:wlmid)
          contest_year.update!(special_depicted_monuments: special_depicted)
        end

        global_special_depicted = Photo.where(year_id: year.id, special: true).where.not(wlmid: [nil, ""]).distinct.count(:wlmid)
        year.update!(special_depicted_monuments: global_special_depicted)
        AnalyticsCalculator.recalculate_year!(year)
      end

      DashboardInsights.clear_cache!
    end
  end
end
