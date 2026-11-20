require "addressable/uri"

module Api
  class UpdateGlobalUsageWorker
    include Sidekiq::Worker
    sidekiq_options({
      # Should be set to true (enables uniqueness for async jobs)
      # or :all (enables uniqueness for both async and scheduled jobs)
      unique: :all
    })

    COMMONS_API_URL = "https://commons.wikimedia.org/w/api.php".freeze

    def perform(*args)
      Photo.in_batches(of: 50) do |batch|
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

      used_pageids = fetch_used_pageids(pageids)
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

    def fetch_used_pageids(pageids)
      used_pageids = {}
      gucontinue = nil

      loop do
        query = {
          action: :query,
          prop: :globalusage,
          pageids: pageids.join("|"),
          gunamespace: 0,
          gulimit: :max,
          format: :json
        }
        query[:gucontinue] = gucontinue if gucontinue

        request = HTTParty.get(COMMONS_API_URL, query: query, uri_adapter: Addressable::URI)
        unless request.parsed_response.is_a?(Hash)
          raise "Risposta non valida da Wikimedia Commons (HTTP #{request.code})"
        end

        data = request.parsed_response
        raise "Errore API Wikimedia Commons: #{data['error']}" if data["error"]

        pages = data.dig("query", "pages")
        raise "Risposta inattesa da Wikimedia Commons: campo query.pages mancante" unless pages.is_a?(Hash)

        pages.each do |pageid, page_data|
          used_pageids[pageid.to_s] = true if page_data.is_a?(Hash) && !page_data["globalusage"].blank?
        end

        gucontinue = data.dig("continue", "gucontinue")
        break if gucontinue.blank?
      end

      used_pageids
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
