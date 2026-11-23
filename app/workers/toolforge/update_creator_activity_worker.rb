module Toolforge
  class UpdateCreatorActivityWorker
    include Sidekiq::Worker
    sidekiq_options({
      unique: :all
    })

    def perform(year_id = nil)
      years = year_id.present? ? Year.where(id: year_id) : Year.order(:year)
      years.each do |year|
        process_year(year)
      end
    end

    private

    def process_year(year)
      y = year.year.to_i
      return if y <= 0

      wlm_counts_by_creator_id = Photo.where(year_id: year.id).group(:creator_id).count
      return if wlm_counts_by_creator_id.empty?

      creators = Creator.where(id: wlm_counts_by_creator_id.keys).index_by(&:id)
      usernames = creators.values.filter_map(&:username).uniq

      jan_start = Time.utc(y, 1, 1, 0, 0, 0)
      dec_end = Time.utc(y, 12, 31, 23, 59, 59)
      sep_start = year.period_start_date.beginning_of_day.utc
      sep_end = year.period_end_date.end_of_day.utc

      total_year_uploads = WikimediaReplicaClient.fetch_user_uploads_in_period(usernames, jan_start, dec_end)
      sep_uploads = WikimediaReplicaClient.fetch_user_uploads_in_period(usernames, sep_start, sep_end)

      after_start = (year.period_end_date + 1.day).beginning_of_day.utc
      after_3m_end = (year.period_end_date + 3.months).end_of_day.utc
      after_12m_end = (year.period_end_date + 12.months).end_of_day.utc

      now_utc = Time.now.utc
      monthly_activity = if now_utc > after_start
                           fetch_end = [after_12m_end, now_utc].min
                           WikimediaReplicaClient.fetch_user_monthly_activity(usernames, after_start, fetch_end)
                         else
                           {}
                         end

      window_3m_months = months_between(after_start, after_3m_end)
      reg_window = year.registration_window_range
      now = Time.current

      wlm_counts_by_creator_id.each do |creator_id, wlm_count|
        creator = creators[creator_id]
        next if creator.nil?

        uname = creator.username
        non_wlm = [total_year_uploads[uname].to_i - sep_uploads[uname].to_i, 0].max
        is_new = !creator.creationdate.nil? && reg_window.cover?(creator.creationdate)

        segment = classify_segment(non_wlm: non_wlm, is_new: is_new)

        user_months = monthly_activity[uname] || {}
        edits_3m = now_utc >= after_3m_end ? user_months.slice(*window_3m_months).values.sum : nil
        edits_12m = now_utc >= after_12m_end ? user_months.values.sum : nil
        active_months_12m = now_utc >= after_12m_end ? user_months.count { |_, cnt| cnt.to_i > 0 } : nil

        record = CreatorYearlyActivity.find_or_initialize_by(creator_id: creator_id, year_id: year.id)
        record.update!(
          wlm_uploads_count: wlm_count,
          non_wlm_uploads_year: non_wlm,
          uploader_segment: segment,
          post_contest_edits_3m: edits_3m,
          post_contest_edits_12m: edits_12m,
          active_months_after_12m: active_months_12m,
          computed_at: now
        )
      end
    end

    def classify_segment(non_wlm:, is_new:)
      if non_wlm >= 100
        "year_round_100_plus"
      elsif non_wlm > 0
        "occasional"
      elsif is_new
        "new_only_wlm"
      else
        "returning_only_wlm"
      end
    end

    def months_between(start_time, end_time)
      months = []
      cursor = Date.new(start_time.year, start_time.month, 1)
      limit = Date.new(end_time.year, end_time.month, 1)
      while cursor <= limit
        months << cursor.strftime("%Y%m")
        cursor = cursor.next_month
      end
      months
    end
  end
end
