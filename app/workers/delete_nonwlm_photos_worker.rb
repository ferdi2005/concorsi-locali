class DeleteNonwlmPhotosWorker
  include Sidekiq::Worker

  def perform(*args)
    if WikimediaReplicaClient.enabled?
      Toolforge::DeleteNonwlmPhotosWorker.new.perform(*args)
    else
      Api::DeleteNonwlmPhotosWorker.new.perform(*args)
    end
  end
end
