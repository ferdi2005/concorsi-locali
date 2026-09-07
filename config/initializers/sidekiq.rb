# config/initializers/sidekiq.rb
# La gemma sidekiq-cron carica in automatico la schedule da config/schedule.yml

toolforge_mode = (ENV["TOOLFORGE"] == "true")

redis_url = if ENV["REDIS_URL"].present? && !(toolforge_mode && ENV["REDIS_URL"].include?("localhost"))
              ENV["REDIS_URL"]
            elsif toolforge_mode
              if ENV["REDIS_PASSWORD"].present?
                "redis://:#{ENV['REDIS_PASSWORD']}@redis:6379/0"
              else
                "redis://redis.svc.tools.eqiad1.wikimedia.cloud:6379/0"
              end
            else
              "redis://localhost:6379/0"
            end

redis_config = { url: redis_url }

# Sull'infrastruttura Toolforge (in particolare su Redis condiviso),
# separiamo le code e i dati di Sidekiq tramite prefisso/namespace univoco
if toolforge_mode || ENV["REDIS_NAMESPACE"].present?
  namespace = ENV["REDIS_NAMESPACE"].presence || "#{ENV['TOOL_TOOLSDB_USER'] || ENV['USER'] || 'concorsilocali'}_sidekiq"
  redis_config[:namespace] = namespace unless namespace == "none"
end

Sidekiq.configure_server do |config|
  config.redis = redis_config
end

Sidekiq.configure_client do |config|
  config.redis = redis_config
end