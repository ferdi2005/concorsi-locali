require "test_helper"

class AnalyticsAndDashboardTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @year2024 = Year.create!(
      year: "2024",
      storicized: true,
      special: true,
      special_category: "fortifications",
      special_category_label: "Fortificazioni",
      total: 4,
      special_category_total: 2,
      creators_count: 2
    )
    @year2025 = Year.create!(
      year: "2025",
      storicized: false,
      special: true,
      special_category: "bridges",
      special_category_label: "Ponti",
      total: 3,
      special_category_total: 1,
      creators_count: 2
    )

    @contest = Contest.create!(name: "WLM Puglia", category: "Puglia", region: "Puglia", url: "https://example.org")
    @cy2024 = ContestYear.create!(contest: @contest, year: @year2024, count: 4, creators: 2, creatorsapposta: 1, monuments: 100, nophoto: 50)
    @cy2025 = ContestYear.create!(contest: @contest, year: @year2025, count: 3, creators: 2, creatorsapposta: 1, monuments: 100, nophoto: 48)

    @veteran = Creator.create!(username: "VeteranUser", userid: 1001, creationdate: Time.utc(2020, 5, 1))
    @new2024 = Creator.create!(username: "New2024User", userid: 1002, creationdate: Time.utc(2024, 9, 5))
    @new2025 = Creator.create!(username: "New2025User", userid: 1003, creationdate: Time.utc(2025, 9, 2))

    # 2024 photos: 3 by veteran (2 special), 1 by new2024 (last 3 days, new_monument, usedonwiki)
    Photo.create!(name: "File:A1.jpg", contest: @contest, creator: @veteran, year: @year2024, pageid: 1, photodate: Time.utc(2024, 9, 2), wlmid: "16A001", special: true, usedonwiki: false, new_monument: false)
    Photo.create!(name: "File:A2.jpg", contest: @contest, creator: @veteran, year: @year2024, pageid: 2, photodate: Time.utc(2024, 9, 10), wlmid: "16A001", special: true, usedonwiki: true, new_monument: false)
    Photo.create!(name: "File:A3.jpg", contest: @contest, creator: @veteran, year: @year2024, pageid: 3, photodate: Time.utc(2024, 9, 12), wlmid: "16A002", special: false, usedonwiki: false, new_monument: false)
    Photo.create!(name: "File:A4.jpg", contest: @contest, creator: @new2024, year: @year2024, pageid: 4, photodate: Time.utc(2024, 9, 29), wlmid: "16A003", special: false, usedonwiki: true, new_monument: true)

    # 2025 photos: 2 by veteran (on 16A001 which already had 2 photos in 2024), 1 by new2025 (on new monument 16A004)
    Photo.create!(name: "File:B1.jpg", contest: @contest, creator: @veteran, year: @year2025, pageid: 5, photodate: Time.utc(2025, 9, 3), wlmid: "16A001", special: true, usedonwiki: false, new_monument: false)
    Photo.create!(name: "File:B2.jpg", contest: @contest, creator: @veteran, year: @year2025, pageid: 6, photodate: Time.utc(2025, 9, 28), wlmid: "16A001", special: false, usedonwiki: false, new_monument: false)
    Photo.create!(name: "File:B3.jpg", contest: @contest, creator: @new2025, year: @year2025, pageid: 7, photodate: Time.utc(2025, 9, 30), wlmid: "16A004", special: false, usedonwiki: true, new_monument: true)

    AnalyticsCalculator.recalculate_all!
  end

  test "analytics calculator computes year and contest_year metrics" do
    ya2024 = @year2024.reload.year_analytic
    assert_not_nil ya2024
    assert_equal 1, ya2024.new_creators_count
    assert_equal 1, ya2024.returning_creators_count
    assert_equal 1, ya2024.last_3_days_photos_count
    assert_equal 25.0, ya2024.last_3_days_photos_share
    assert_equal 1, ya2024.creators_for_50_percent
    assert_equal 3, ya2024.single_author_monuments_count

    cya2024 = @cy2024.reload.contest_year_analytic
    assert_not_nil cya2024
    assert_equal @veteran.id, cya2024.top1_creator_id
    assert_equal 3, cya2024.top1_photos_count
    assert_equal 75.0, cya2024.top1_photos_share
  end

  test "simulator excludes monuments with existing photos from previous years" do
    res = AnalyticsCalculator.simulate(year_ids: [@year2025.id], max_existing_monument_photos: 2, exclude_top_creators: 0)
    assert_equal 1, res.size
    row = res.first
    assert_equal "2025", row[:year]
    assert_equal 3, row[:total_photos]
    assert_equal 1, row[:remaining_photos]
    assert_equal 2, row[:removed_photos]
    assert_equal 2, row[:total_monuments]
    assert_equal 1, row[:excluded_monuments]
    assert_equal 1, row[:removed_creators]
    assert_equal 0, row[:removed_new_monuments]
  end

  test "numerics totalcreators and miglioriutenti include veteran participants" do
    get "/numerics/totalcreators.json", params: { year: "2024" }
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal 2, json["data"]["value"]

    get "/numerics/miglioriutenti.json", params: { year: "2024" }
    assert_response :success
    json = JSON.parse(response.body)
    names = json["data"].map { |d| d["name"] }
    assert_equal ["VeteranUser", "New2024User"], names
    assert_equal 3, json["data"].first["value"]
  end

  test "dashboard routes render successfully" do
    get root_path
    assert_response :success
    refute_includes response.body, "id=\"setanno\""
    assert_includes response.body, "Dati nazionali"

    get root_path(year: "2024")
    assert_response :success
    assert_includes response.body, "Dati nazionali 2024"

    get storico_path
    assert_response :success

    get storico_path, params: { simulate: "1", sim_max_photos: 2, sim_exclude_top: 0 }
    assert_response :success
    assert_includes response.body, "Monumenti esclusi / ritratti"

    get contest_path(@contest, year: "2024")
    assert_response :success

    get creator_path(@veteran, year: "2024")
    assert_response :success
  end

  test "phase 3 exif parser, monuments sentinels, pageviews and recent monuments maintenance view" do
    # EXIF JSON parsing (smartphone)
    json_meta = '{"data":{"Make":"Apple","Model":"iPhone 15 Pro","DateTimeOriginal":"2023:08:10 14:22:00"}}'
    parsed = Toolforge::UpdateExifWorker.extract_exif_fields(json_meta)
    assert_equal true, parsed[:has_exif]
    assert_equal "smartphone", parsed[:device_category]
    assert_equal "Apple", parsed[:camera_make]
    assert_equal 2023, parsed[:taken_at].year

    # EXIF PHP serialized parsing (camera)
    php_meta = 'a:3:{s:4:"Make";s:5:"Canon";s:5:"Model";s:19:"PowerShot SX740 HS";s:16:"DateTimeOriginal";s:19:"2024:09:05 10:00:00";}'
    parsed_php = Toolforge::UpdateExifWorker.extract_exif_fields(php_meta)
    assert_equal true, parsed_php[:has_exif]
    assert_equal "camera", parsed_php[:device_category]
    assert_equal "Canon", parsed_php[:camera_make]

    # Project domain mapping
    assert_equal "it.wikipedia.org", PhotoUsage.project_domain_for_wiki("itwiki")
    assert_equal "en.wikivoyage.org", PhotoUsage.project_domain_for_wiki("enwikivoyage")

    # Populate Phase 3 records
    Monument.create!(
      item: "Q999001",
      wlmid: "16A001",
      normalized_wlmid: "16A001",
      label: "Ponte moderno di prova",
      regione: "Puglia",
      city: "Piccolo Comune",
      city_item: "Q111",
      municipality_population: 2500,
      monument_type: "ponte",
      inception_year: 1972,
      mic_catalog_id: "1600123456",
      has_wikipedia: false,
      has_commons_category: false,
      has_p18: false,
      photos_count: 5
    )

    photo = Photo.find_by!(name: "File:A2.jpg")
    photo.update!(taken_at: Time.utc(2022, 6, 1), device_category: "smartphone", has_exif: true, exif_checked_at: Time.current)
    PhotoUsage.create!(photo: photo, wiki: "itwiki", page_title: "Bari", active: true)
    WikiPageMonthlyView.create!(wiki: "itwiki", page_title: "Bari", year_month: "202509", views: 12345)
    CreatorYearlyActivity.create!(
      creator: @veteran,
      year: @year2024,
      wlm_uploads_count: 3,
      non_wlm_uploads_year: 150,
      uploader_segment: "year_round_100_plus",
      post_contest_edits_3m: 20,
      post_contest_edits_12m: 80,
      active_months_after_12m: 6,
      computed_at: Time.current
    )

    original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
    begin
      get storico_path
      assert_response :success
      assert_includes response.body, "Piccoli comuni, tipologie e sentinelle"
      assert_includes response.body, "Metadati EXIF"
      assert_includes response.body, "Impatto su Wikipedia"
    ensure
      Rails.cache = original_cache
    end

    get recent_monuments_maintenance_path, params: { threshold: 1950, regione: "Puglia" }
    assert_response :success
    assert_includes response.body, "Ponte moderno di prova"
    assert_includes response.body, "1972"

    get contest_path(@contest, year: "2024")
    assert_response :success
    assert_includes response.body, "Comuni piccoli, tipologie e sentinelle"
    assert_includes response.body, "Metadati EXIF e dispositivi nel concorso"
    assert_includes response.body, "Monumenti più fotografati"
  end
end
