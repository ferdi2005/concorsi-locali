Sidekiq::Cron::Job.create(name: 'Update Data Job every 10 minutes', cron: '*/10 * * * *', class: 'UpdateDataJob')