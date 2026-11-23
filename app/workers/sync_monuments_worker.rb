class SyncMonumentsWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: :all
  })

  DEFAULT_ENDPOINT = "https://wlm-italy.toolforge.org/monuments/analytics_endpoint.json".freeze

  def perform
    url = ENV["CERCA_ANALYTICS_ENDPOINT"].presence || DEFAULT_ENDPOINT
    response = HTTParty.get(url, timeout: 180)
    raise "Errore nel download da #{url}: HTTP #{response.code}" unless response.success?

    rows = response.parsed_response
    rows = JSON.parse(response.body) if rows.is_a?(String)
    return unless rows.is_a?(Array) && rows.any?

    now = Time.current
    records = rows.filter_map do |row|
      item = row["item"].to_s.strip
      next if item.empty?

      raw_wlmid = row["wlmid"].to_s.strip
      {
        item: item,
        wlmid: raw_wlmid.presence,
        normalized_wlmid: raw_wlmid.empty? ? nil : AnalyticsCalculator.normalize_wlmid(raw_wlmid),
        label: row["label"],
        regione: row["regione"],
        city: row["city"],
        city_item: row["city_item"],
        municipality_population: row["municipality_population"]&.to_i,
        monument_type: row["monument_type"],
        instanceof_qid: row["instanceof_qid"],
        inception_year: row["inception_year"]&.to_i,
        mic_catalog_id: row["mic_catalog_id"],
        has_wikipedia: row["has_wikipedia"] == true,
        has_commons_category: row["has_commons_category"] == true,
        has_p18: row["has_p18"] == true,
        photos_count: row["photos_count"].to_i,
        commonsphotos: row["commonsphotos"].to_i,
        hidden: row["hidden"] == true,
        created_at: now,
        updated_at: now
      }
    end

    records.each_slice(2000) do |slice|
      if Monument.connection.supports_insert_conflict_target?
        Monument.upsert_all(slice, unique_by: :item)
      else
        Monument.upsert_all(slice)
      end
    end
  end
end
