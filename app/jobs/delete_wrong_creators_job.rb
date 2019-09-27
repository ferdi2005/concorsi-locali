class DeleteWrongCreatorsJob < ApplicationJob
  queue_as :default

  def perform(*args)
    Creator.where(username: nil).each do |c|
      if c.photos.count == 0
        c.destroy
      end
    end
  end
end
