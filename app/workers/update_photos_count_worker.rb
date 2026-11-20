class UpdatePhotosCountWorker
  include Sidekiq::Worker
  sidekiq_options({
    unique: true
  })

  def perform(*args)
    if WikimediaReplicaClient.enabled?
      Toolforge::UpdatePhotosCountWorker.new.perform(*args)
    else
      Api::UpdatePhotosCountWorker.new.perform(*args)
    end
  end
end
