require "httparty"
require "time"

module HTTPartyRateLimitRetry
  RETRYABLE_STATUS_CODES = [429, 502, 503, 504].freeze
  MAX_RETRIES = 5

  private

  def perform_request(http_method, path, options, &block)
    attempts = 0

    loop do
      request_options = HTTParty::ModuleInheritableAttributes.hash_deep_dup(options || {})
      response = super(http_method, path, request_options, &block)
      return response unless response.respond_to?(:code) && RETRYABLE_STATUS_CODES.include?(response.code) && attempts < MAX_RETRIES

      attempts += 1
      wait_seconds = retry_after_seconds(response, attempts)
      log_retry(response, path, wait_seconds, attempts)
      sleep(wait_seconds)
    end
  end

  def retry_after_seconds(response, attempt)
    raw_header = response.headers&.[]("retry-after")
    header_value = raw_header.is_a?(Array) ? raw_header.first : raw_header
    retry_after = header_value.to_i

    if retry_after <= 0 && !header_value.nil? && !header_value.to_s.strip.empty?
      begin
        retry_after = (Time.httpdate(header_value.to_s) - Time.now).ceil
      rescue ArgumentError
        retry_after = 0
      end
    end

    retry_after.positive? ? retry_after : (2**attempt)
  end

  def log_retry(response, path, wait_seconds, attempt)
    message = "[HTTParty] HTTP #{response.code} su #{path}, attesa di #{wait_seconds}s prima del tentativo #{attempt}/#{MAX_RETRIES}"
    logger = if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger
               Rails.logger
             elsif defined?(Sidekiq) && Sidekiq.respond_to?(:logger) && Sidekiq.logger
               Sidekiq.logger
             end

    if logger
      logger.warn(message)
    else
      warn(message)
    end
  end
end

HTTParty::Basement.headers(
  "User-Agent" => ENV.fetch(
    "WIKIMEDIA_USER_AGENT",
    "ConcorsiLocali/1.0 (https://concorsi.wikilovesmonuments.it; ferdi.traversa@gmail.com) HTTParty/#{HTTParty::VERSION} Ruby/#{RUBY_VERSION}"
  )
)

unless HTTParty::Basement.singleton_class.ancestors.include?(HTTPartyRateLimitRetry)
  HTTParty::Basement.singleton_class.prepend(HTTPartyRateLimitRetry)
end
