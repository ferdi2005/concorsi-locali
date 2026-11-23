require "set"

class AnalyticsCalculator
  BUCKET_LABELS = {
    "1" => "1 foto",
    "2_5" => "2-5 foto",
    "6_20" => "6-20 foto",
    "gt_20" => "Oltre 20 foto"
  }.freeze

  def self.recalculate_all!
    Year.order(:year).each do |year|
      recalculate_year!(year)
    end
  end

  def self.recalculate_year!(year)
    new(year).recalculate!
  end

  def self.top_uploaders_across_years(limit: 50)
    per_year_counts = Photo.group(:year_id, :creator_id).count
    return [] if per_year_counts.empty?

    years_by_id = Year.all.index_by(&:id)
    photos_by_year = Hash.new { |h, k| h[k] = [] }
    per_year_counts.each do |(year_id, creator_id), cnt|
      photos_by_year[year_id] << [creator_id, cnt]
    end

    top10_years_by_creator = Hash.new { |h, k| h[k] = [] }
    editions_by_creator = Hash.new { |h, k| h[k] = [] }
    total_photos_by_creator = Hash.new(0)

    photos_by_year.each do |year_id, pairs|
      year_label = years_by_id[year_id]&.year.to_s
      sorted = pairs.sort_by { |_, cnt| -cnt }
      sorted.each_with_index do |(creator_id, cnt), idx|
        total_photos_by_creator[creator_id] += cnt
        editions_by_creator[creator_id] << year_label
        top10_years_by_creator[creator_id] << year_label if idx < 10
      end
    end

    top_ids = total_photos_by_creator.sort_by { |_, cnt| -cnt }.first(limit).map(&:first)
    creators = Creator.where(id: top_ids).index_by(&:id)

    top_ids.filter_map do |creator_id|
      creator = creators[creator_id]
      next if creator.nil?

      editions = editions_by_creator[creator_id].sort
      top10_years = top10_years_by_creator[creator_id].sort
      {
        creator: creator,
        total_photos: total_photos_by_creator[creator_id],
        editions_count: editions.size,
        editions: editions,
        top10_count: top10_years.size,
        top10_years: top10_years
      }
    end
  end

  def self.simulate(year_ids: nil, max_existing_monument_photos: nil, exclude_top_creators: 0)
    years = if year_ids.present?
              Year.where(id: year_ids).order(:year).to_a
            else
              Year.order(:year).to_a
            end
    return [] if years.empty?

    all_years = Year.order(:year).to_a
    cumulative_by_wlmid = Hash.new(0)
    selected_ids = years.map(&:id).to_set
    results = []

    all_years.each do |year|
      year_photos = Photo.where(year_id: year.id)
      total_photos = year_photos.count
      wlmid_counts_this_year = year_photos.where.not(wlmid: [nil, ""]).group(:wlmid).count

      if selected_ids.include?(year.id)
        excluded_wlmids = Set.new
        if max_existing_monument_photos && max_existing_monument_photos > 0
          wlmid_counts_this_year.each_key do |wlmid|
            norm = normalize_wlmid(wlmid)
            excluded_wlmids.add(wlmid) if cumulative_by_wlmid[norm] >= max_existing_monument_photos
          end
        end

        excluded_creator_ids = Set.new
        if exclude_top_creators && exclude_top_creators > 0
          top_ids = year_photos.group(:creator_id).order(Arel.sql("COUNT(*) DESC")).limit(exclude_top_creators).pluck(:creator_id)
          excluded_creator_ids.merge(top_ids)
        end

        remaining_scope = year_photos
        remaining_scope = remaining_scope.where.not(wlmid: excluded_wlmids.to_a) if excluded_wlmids.any?
        remaining_scope = remaining_scope.where.not(creator_id: excluded_creator_ids.to_a) if excluded_creator_ids.any?

        remaining_photos = remaining_scope.count
        removed_photos = total_photos - remaining_photos
        removed_share = total_photos > 0 ? (removed_photos.to_f / total_photos * 100.0).round(1) : 0.0
        remaining_creators = remaining_scope.distinct.count(:creator_id)
        total_creators = year_photos.distinct.count(:creator_id)
        remaining_new_monuments = remaining_scope.where(new_monument: true).count
        total_new_monuments = year_photos.where(new_monument: true).count

        results << {
          year: year.year,
          total_photos: total_photos,
          remaining_photos: remaining_photos,
          removed_photos: removed_photos,
          removed_share: removed_share,
          total_creators: total_creators,
          remaining_creators: remaining_creators,
          total_new_monuments: total_new_monuments,
          remaining_new_monuments: remaining_new_monuments
        }
      end

      wlmid_counts_this_year.each do |wlmid, cnt|
        cumulative_by_wlmid[normalize_wlmid(wlmid)] += cnt
      end
    end

    results
  end

  def self.normalize_wlmid(raw)
    s = raw.to_s.strip
    s.sub(/\A0+(?=\d)/, "")
  end

  def initialize(year)
    @year = year
  end

  def recalculate!
    now = Time.current
    compute_year_analytic!(now)
    compute_contest_year_analytics!(now)
  end

  private

  def compute_year_analytic!(now)
    scope = Photo.where(year_id: @year.id)
    total_photos = scope.count

    creator_counts = scope.group(:creator_id).count
    sorted_creators = creator_counts.sort_by { |_, cnt| -cnt }
    total_creators = sorted_creators.size

    new_count, returning_count, unknown_count = split_creators_by_registration(sorted_creators.map(&:first))

    top10_pairs = sorted_creators.first(10)
    top10_ids = top10_pairs.map(&:first)
    top10_photos = top10_pairs.sum { |_, cnt| cnt }
    photos_without_top10 = total_photos - top10_photos
    top10_share = pct(top10_photos, total_photos)

    creators_50 = count_for_share(sorted_creators, total_photos, 0.5)
    creators_90 = count_for_share(sorted_creators, total_photos, 0.9)
    bottom_half_share = bottom_half_share_for(sorted_creators, total_photos)

    last_3_start = (@year.period_end_date - 2.days).beginning_of_day
    last_3_end = @year.period_end_date.end_of_day
    last_3_photos = scope.where(photodate: last_3_start..last_3_end).count
    last_3_share = pct(last_3_photos, total_photos)

    special_scope = scope.where(special: true)
    special_creators = special_scope.distinct.count(:creator_id)
    special_creators_share = pct(special_creators, total_creators)

    non_top10_scope = top10_ids.any? ? scope.where.not(creator_id: top10_ids) : scope
    special_without_top10 = non_top10_scope.where(special: true).count
    special_share_without_top10 = pct(special_without_top10, photos_without_top10)
    special_creators_without_top10 = non_top10_scope.where(special: true).distinct.count(:creator_id)
    special_per_creator_without_top10 = special_creators_without_top10 > 0 ? (special_without_top10.to_f / special_creators_without_top10).round(2) : 0.0

    monument_stats = compute_monument_stats(scope)
    bluification_count, bluification_rate = compute_bluification(nil)
    reuse_buckets = compute_reuse_buckets(scope)

    analytic = YearAnalytic.find_or_initialize_by(year_id: @year.id)
    analytic.assign_attributes(
      new_creators_count: new_count,
      returning_creators_count: returning_count,
      unknown_registration_creators_count: unknown_count,
      top10_photos_count: top10_photos,
      top10_photos_share: top10_share,
      photos_without_top10: photos_without_top10,
      creators_for_50_percent: creators_50,
      creators_for_90_percent: creators_90,
      bottom_half_photos_share: bottom_half_share,
      last_3_days_photos_count: last_3_photos,
      last_3_days_photos_share: last_3_share,
      special_creators_count: special_creators,
      special_creators_share: special_creators_share,
      special_photos_without_top10: special_without_top10,
      special_share_without_top10: special_share_without_top10,
      special_photos_per_creator_without_top10: special_per_creator_without_top10,
      monuments_for_50_percent_photos: monument_stats[:monuments_for_50_percent],
      single_author_monuments_count: monument_stats[:single_author_count],
      single_author_monuments_share: monument_stats[:single_author_share],
      avg_photos_per_monument: monument_stats[:avg_photos],
      median_photos_per_monument: monument_stats[:median_photos],
      bluification_count: bluification_count,
      bluification_rate: bluification_rate,
      computed_at: now
    )
    analytic.reuse_by_monument_bucket = reuse_buckets
    analytic.top_monuments = monument_stats[:top_monuments]
    analytic.save!
  end

  def compute_contest_year_analytics!(now)
    last_3_start = (@year.period_end_date - 2.days).beginning_of_day
    last_3_end = @year.period_end_date.end_of_day

    ContestYear.where(year_id: @year.id).find_each do |contest_year|
      scope = Photo.where(year_id: @year.id, contest_id: contest_year.contest_id)
      total_photos = scope.count
      creator_counts = scope.group(:creator_id).count
      sorted_creators = creator_counts.sort_by { |_, cnt| -cnt }

      new_count, returning_count, _unknown = split_creators_by_registration(sorted_creators.map(&:first))
      top1_creator_id, top1_photos = sorted_creators.first || [nil, 0]
      top10_photos = sorted_creators.first(10).sum { |_, cnt| cnt }
      last_3_photos = scope.where(photodate: last_3_start..last_3_end).count
      monument_stats = compute_monument_stats(scope, include_top: false)

      analytic = ContestYearAnalytic.find_or_initialize_by(contest_year_id: contest_year.id)
      analytic.update!(
        new_creators_count: new_count,
        returning_creators_count: returning_count,
        top1_creator_id: top1_creator_id,
        top1_photos_count: top1_photos,
        top1_photos_share: pct(top1_photos, total_photos),
        top10_photos_share: pct(top10_photos, total_photos),
        photos_without_top10: total_photos - top10_photos,
        last_3_days_photos_share: pct(last_3_photos, total_photos),
        single_author_monuments_share: monument_stats[:single_author_share],
        computed_at: now
      )
    end
  end

  def split_creators_by_registration(creator_ids)
    return [0, 0, 0] if creator_ids.empty?

    window = @year.registration_window_range
    new_count = 0
    returning_count = 0
    unknown_count = 0

    Creator.where(id: creator_ids).pluck(:creationdate).each do |creationdate|
      if creationdate.nil?
        unknown_count += 1
      elsif window.cover?(creationdate)
        new_count += 1
      else
        returning_count += 1
      end
    end

    [new_count, returning_count, unknown_count]
  end

  def compute_monument_stats(scope, include_top: true)
    valid_scope = scope.where.not(wlmid: [nil, ""])
    rows = valid_scope.group(:wlmid).pluck(
      :wlmid,
      Arel.sql("COUNT(*)"),
      Arel.sql("COUNT(DISTINCT creator_id)")
    )

    merged = Hash.new { |h, k| h[k] = { count: 0, authors: 0, raw: nil } }
    rows.each do |wlmid, cnt, authors|
      norm = self.class.normalize_wlmid(wlmid)
      merged[norm][:count] += cnt.to_i
      merged[norm][:authors] = [merged[norm][:authors], authors.to_i].max
      merged[norm][:raw] ||= wlmid
    end

    monuments_count = merged.size
    if monuments_count == 0
      return {
        monuments_for_50_percent: 0,
        single_author_count: 0,
        single_author_share: 0.0,
        avg_photos: 0.0,
        median_photos: 0.0,
        top_monuments: []
      }
    end

    counts = merged.values.map { |v| v[:count] }.sort.reverse
    total_with_wlmid = counts.sum
    monuments_50 = count_for_share(counts.each_with_index.map { |c, i| [i, c] }, total_with_wlmid, 0.5)
    single_author_count = merged.values.count { |v| v[:authors] == 1 }

    top_monuments = if include_top
                      merged.sort_by { |_, v| -v[:count] }.first(20).map do |norm, v|
                        { "wlmid" => v[:raw] || norm, "photos" => v[:count], "authors" => v[:authors] }
                      end
                    else
                      []
                    end

    {
      monuments_for_50_percent: monuments_50,
      single_author_count: single_author_count,
      single_author_share: pct(single_author_count, monuments_count),
      avg_photos: (total_with_wlmid.to_f / monuments_count).round(2),
      median_photos: median(counts),
      top_monuments: top_monuments
    }
  end

  def compute_reuse_buckets(scope)
    valid_scope = scope.where.not(wlmid: [nil, ""])
    per_monument = valid_scope.group(:wlmid).pluck(
      :wlmid,
      Arel.sql("COUNT(*)"),
      Arel.sql("SUM(CASE WHEN usedonwiki = true THEN 1 ELSE 0 END)")
    )

    merged = Hash.new { |h, k| h[k] = { total: 0, used: 0 } }
    per_monument.each do |wlmid, total, used|
      norm = self.class.normalize_wlmid(wlmid)
      merged[norm][:total] += total.to_i
      merged[norm][:used] += used.to_i
    end

    buckets = {
      "1" => { "total" => 0, "used" => 0, "rate" => 0.0 },
      "2_5" => { "total" => 0, "used" => 0, "rate" => 0.0 },
      "6_20" => { "total" => 0, "used" => 0, "rate" => 0.0 },
      "gt_20" => { "total" => 0, "used" => 0, "rate" => 0.0 }
    }

    merged.each_value do |stats|
      key = case stats[:total]
            when 1 then "1"
            when 2..5 then "2_5"
            when 6..20 then "6_20"
            else "gt_20"
            end
      buckets[key]["total"] += stats[:total]
      buckets[key]["used"] += stats[:used]
    end

    buckets.each_value do |b|
      b["rate"] = pct(b["used"], b["total"])
    end

    new_total = scope.where(new_monument: true).count
    new_used = scope.where(new_monument: true, usedonwiki: true).count
    existing_total = scope.where(new_monument: [false, nil]).count
    existing_used = scope.where(new_monument: [false, nil], usedonwiki: true).count

    {
      "buckets" => buckets,
      "new_monument" => {
        "total" => new_total,
        "used" => new_used,
        "rate" => pct(new_used, new_total)
      },
      "existing_monument" => {
        "total" => existing_total,
        "used" => existing_used,
        "rate" => pct(existing_used, existing_total)
      }
    }
  end

  def compute_bluification(regione)
    records = Nophoto.where(year_id: @year.id, regione: regione).order(:created_at)
    first_rec = records.first
    last_rec = records.last
    return [nil, nil] if first_rec.nil? || last_rec.nil? || first_rec.id == last_rec.id
    return [nil, nil] if first_rec.count.to_i <= 0

    delta = first_rec.count.to_i - last_rec.count.to_i
    rate = (delta.to_f / first_rec.count.to_f * 100.0).round(2)
    [delta, rate]
  end

  def count_for_share(sorted_pairs, total, threshold)
    return 0 if total <= 0 || sorted_pairs.empty?

    target = total * threshold
    acc = 0
    sorted_pairs.each_with_index do |(_, cnt), idx|
      acc += cnt
      return idx + 1 if acc >= target
    end
    sorted_pairs.size
  end

  def bottom_half_share_for(sorted_pairs, total)
    return 0.0 if total <= 0 || sorted_pairs.empty?

    half_size = (sorted_pairs.size / 2.0).floor
    return 0.0 if half_size <= 0

    bottom_photos = sorted_pairs.last(half_size).sum { |_, cnt| cnt }
    pct(bottom_photos, total)
  end

  def median(sorted_desc)
    n = sorted_desc.size
    return 0.0 if n == 0

    mid = n / 2
    if n.odd?
      sorted_desc[mid].to_f
    else
      ((sorted_desc[mid - 1] + sorted_desc[mid]) / 2.0).round(2)
    end
  end

  def pct(part, total)
    return 0.0 if total.to_i <= 0

    (part.to_f / total.to_f * 100.0).round(2)
  end
end
