unless Rails.env.test?
  require 'sidekiq/api'

  @redis_url = ENV.fetch('REDIS_URL_SIDEKIQ', 'redis://redis/0')
  @password  = ENV['REDIS_PASSWORD']

  Sidekiq.configure_server do |config|
    config.redis = {
      url: @redis_url,
      password: @password
    }
  end

  Sidekiq.configure_client do |config|
    config.redis = {
      url: @redis_url,
      password: @password
    }
  end
end
