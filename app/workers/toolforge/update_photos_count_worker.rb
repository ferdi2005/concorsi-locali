module Toolforge
  class UpdatePhotosCountWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: true
    })

    def perform(*args)
      contests = Contest.all.to_a

      Year.where(storicized: false).each do |year|
        category_titles = []
        contests.each do |contest|
          category_titles << contest.cat_name(year)
          if year.special
            category_titles << "#{contest.cat_name(year)} #{year.special_category.to_s.strip}"
          end
        end

        counts_by_cat = WikimediaReplicaClient.fetch_category_files_counts(category_titles)
        global_photo_count = 0
        global_special_category_count = 0

        contests.each do |contest|
          contestyear = ContestYear.find_by(contest: contest, year: year) ||
                        ContestYear.create!(contest: contest, year: year)

          main_title = WikimediaReplicaClient.normalize_category_title(contest.cat_name(year))
          photos_count = counts_by_cat[main_title] || 0
          global_photo_count += photos_count.to_i

          if year.special
            special_title = WikimediaReplicaClient.normalize_category_title(
              "#{contest.cat_name(year)} #{year.special_category.to_s.strip}"
            )
            special_category_count = counts_by_cat[special_title] || 0
          else
            special_category_count = 0
          end

          global_special_category_count += special_category_count.to_i
          contestyear.update!(count: photos_count, special_category_count: special_category_count)
        end

        year.update!(total: global_photo_count, special_category_total: global_special_category_count)

        contests.each do |contest|
          contestyear = ContestYear.find_by(contest: contest, year: year)
          next if contestyear.nil?

          percent_of_total = global_photo_count.to_i > 0 ? (contestyear.count.to_f / global_photo_count.to_f * 100) : 0
          special_category_percent_of_total = global_special_category_count.to_i > 0 ? (contestyear.special_category_count.to_f / global_special_category_count.to_f * 100) : 0

          contestyear.update!(
            percent_of_total: percent_of_total,
            special_category_percent_of_total: special_category_percent_of_total
          )
        end
      end
    end
  end
end
