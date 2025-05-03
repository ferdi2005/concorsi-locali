class UpdatePhotosCountWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })

  def perform(*args)
    Year.where(storicized: false).each do |year|
      global_photo_count = 0
      global_special_category_count = 0
      Contest.all.each do |contest|
        unless (contestyear = ContestYear.find_by(contest: contest, year: year))
          contestyear = ContestYear.create!(contest: contest, year: year)
        end
        # Richiede le foto della categoria
        commons_url = "https://commons.wikimedia.org/w/api.php"
        request = HTTParty.get(commons_url, query: {action: :query, prop: :categoryinfo, titles: contest.cat_name(year), format: :json}, uri_adapter: Addressable::URI).to_h

        photos_count = request["query"]["pages"].first[1]["categoryinfo"].try(:[], "files")
        global_photo_count += photos_count.to_i
        # Procede con la categoria speciale
        if year.special
          commons_url = "https://commons.wikimedia.org/w/api.php"
          request = HTTParty.get(commons_url, query: {action: :query, prop: :categoryinfo, titles: contest.cat_name(year) + " " + year.special_category.strip, format: :json}, uri_adapter: Addressable::URI).to_h

          special_category_count = request["query"]["pages"].first[1]["categoryinfo"].try(:[], "files")
        else
          special_category_count = 0
        end

        global_special_category_count += special_category_count.to_i
        # Aggiorna il conto delle fotografie del concorso facendo la percentuale rispetto al totale
        contestyear.update!(count: photos_count, special_category_count: special_category_count)
      end
      # Aggiornamento dati globali
      year.update!(total: global_photo_count, special_category_total: global_special_category_count)

      # Aggiornamento delle percentuali
      Contest.all.each do |contest|
        contestyear = ContestYear.find_by(contest: contest, year: year)

        global_photo_count != 0 ? percent_of_total = contestyear.count.to_f / global_photo_count.to_f * 100 : percent_of_total = 0

        global_special_category_count != 0 ? special_category_percent_of_total = contestyear.special_category_count.to_f / global_special_category_count.to_f * 100 : special_category_percent_of_total = 0

        contestyear.update!(percent_of_total: percent_of_total, special_category_percent_of_total: special_category_percent_of_total)
      end
    end
  end
end
