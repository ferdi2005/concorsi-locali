require "uri"

class UpdatePageviewsWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: :all
  })

  API_BASE = "https://wikimedia.org/api/rest_v1/metrics/pageviews/per-article".freeze
  USER_AGENT = "WikiLovesMonumentsItaliaStats/1.0 (https://github.com/ferdi2005/concorsi-locali; ferdi.traversa@gmail.com)".freeze

  # Recupera le visite mensili per gli ultimi `months_back` mesi chiusi
  # saltando i mesi già presenti in wiki_page_monthly_views.
  def perform(months_back = 12, max_pages = 3000)
    target_months = closed_months(months_back)
    return if target_months.empty?

    start_param = "#{target_months.first}01"
    end_date = Date.strptime("#{target_months.last}01", "%Y%m%d").end_of_month
    end_param = end_date.strftime("%Y%m%d")

    pages = PhotoUsage.active.distinct.pluck(:wiki, :page_title).first(max_pages)
    return if pages.empty?

    existing = WikiPageMonthlyView
      .where(year_month: target_months)
      .pluck(:wiki, :page_title, :year_month)
      .each_with_object(Hash.new { |h, k| h[k] = Set.new }) do |(w, t, ym), acc|
        acc[[w, t]].add(ym)
      end

    now = Time.current
    to_upsert = []

    pages.each do |wiki, page_title|
      have_months = existing[[wiki, page_title]]
      next if (target_months - have_months.to_a).empty?

      project = PhotoUsage.project_domain_for_wiki(wiki)
      next if project.nil?

      encoded_title = URI.encode_www_form_component(page_title.tr(" ", "_")).gsub("+", "%20")
      url = "#{API_BASE}/#{project}/all-access/user/#{encoded_title}/monthly/#{start_param}/#{end_param}"

      response = HTTParty.get(url, headers: { "User-Agent" => USER_AGENT }, timeout: 20)
      if response.success?
        items = response.parsed_response.is_a?(Hash) ? response.parsed_response["items"] : nil
        Array(items).each do |item|
          ym = item["timestamp"].to_s[0, 6]
          next unless target_months.include?(ym)

          to_upsert << {
            wiki: wiki,
            page_title: page_title,
            year_month: ym,
            views: item["views"].to_i,
            created_at: now,
            updated_at: now
          }
        end
      elsif response.code == 404
        target_months.each do |ym|
          next if have_months.include?(ym)

          to_upsert << {
            wiki: wiki,
            page_title: page_title,
            year_month: ym,
            views: 0,
            created_at: now,
            updated_at: now
          }
        end
      end

      flush_upserts!(to_upsert) if to_upsert.size >= 1000
      sleep 0.05
    rescue StandardError => e
      Rails.logger.warn("[UpdatePageviewsWorker] Errore su #{wiki}/#{page_title}: #{e.message}")
    end

    flush_upserts!(to_upsert) if to_upsert.any?
  end

  private

  def closed_months(months_back)
    last_closed = Date.today.beginning_of_month - 1.month
    (0...months_back).map { |i| (last_closed << i).strftime("%Y%m") }.reverse
  end

  def flush_upserts!(records)
    if WikiPageMonthlyView.connection.supports_insert_conflict_target?
      WikiPageMonthlyView.upsert_all(records, unique_by: :index_wiki_page_monthly_views_uniqueness)
    else
      WikiPageMonthlyView.upsert_all(records)
    end
    records.clear
  end
end
