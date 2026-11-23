class UpdateAnalyticsWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: :all
  })

  def perform(year_id = nil)
    if year_id.present?
      year = Year.find_by(id: year_id)
      AnalyticsCalculator.recalculate_year!(year) if year
    else
      Year.where(storicized: false).find_each do |year|
        AnalyticsCalculator.recalculate_year!(year)
      end
    end
  end
end
