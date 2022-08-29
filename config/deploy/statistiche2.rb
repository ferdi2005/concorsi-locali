set :application, "statistiche2"
set :deploy_to,       "/home/#{fetch(:user)}/apps/#{fetch(:application)}"
set :puma_bind,       "unix://#{shared_path}/tmp/sockets/#{fetch(:application)}-puma.sock"
set :sidekiq_service_unit_name, "#{fetch(:application)}-sidekiq"

set :puma_state,      "#{shared_path}/tmp/pids/puma.state"
set :puma_pid,        "#{shared_path}/tmp/pids/puma.pid"
set :puma_access_log, "#{release_path}/log/puma.access.log"
set :puma_error_log,  "#{release_path}/log/puma.error.log"

namespace :deploy do
    namespace :check do
      before :linked_files, :upload_env do
        on roles(:app), in: :sequence, wait: 10 do
            puts "Uploading .env file..."
            upload! '.env2', "#{shared_path}/.env"
        end
      end
    end
end
