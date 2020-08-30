class FirstWlmDataPopulationWorker
  include Sidekiq::Worker

  def perform(*args)
    UpdateNophotoDataWorker.perform_async
  end
end
