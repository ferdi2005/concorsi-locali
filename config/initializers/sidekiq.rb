Sidekiq::Cron::Job.create(name: 'Update Data Job', cron: '*/20 * * 9 *', class: 'UpdateDataJob')
Sidekiq::Cron::Job.create(name: 'Update Global Usage', cron: '01 0 * * *', class: 'UpdateGlobalUsageJob')
Sidekiq::Cron::Job.create(name: 'Update Photos Count Job', cron: '*/5 * * * *', class: 'UpdatePhotosCountJob')
Sidekiq::Cron::Job.create(name: 'Delete Wrong Creators Job', cron: '*/10 * * * *', class: 'DeleteWrongCreatorsJob')