class UpdateGlobalUsageWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: :all
  })

  def perform(*args)
    if WikimediaReplicaClient.enabled?
      Toolforge::UpdateGlobalUsageWorker.new.perform(*args)
    else
      Api::UpdateGlobalUsageWorker.new.perform(*args)
    end
  end
end
