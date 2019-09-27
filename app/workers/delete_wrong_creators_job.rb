class DeleteWrongCreatorsWorker
  include Sidekiq::Worker
  sidekiq_options({
    # Should be set to true (enables uniqueness for async jobs)
    # or :all (enables uniqueness for both async and scheduled jobs)
    unique: true
  })

  def perform(*args)
    Creator.where(username: nil).each do |c|
      if c.photos.count == 0
        c.destroy
      end
    end
  end
end
