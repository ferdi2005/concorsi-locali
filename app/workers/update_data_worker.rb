class UpdateDataWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: :all
  })

  def perform(*args)
    if WikimediaReplicaClient.enabled?
      Toolforge::UpdateDataWorker.new.perform(*args)
    else
      Api::UpdateDataWorker.new.perform(*args)
    end
  end
end
