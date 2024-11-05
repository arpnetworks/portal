Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    port   = ENV.fetch('PORT', 3000)
    origin = ENV.fetch('CORS_ORIGIN', 'arpnetworks.com')

    if Rails.env.production?
        origins origin, "arpnetworks.com", "orders.arpnetworks.com"
      else
        origins origin, "localhost:#{port}", "127.0.0.1:#{port}", "[::1]:#{port}", "localhost:3001", "localhost:3002", "localhost:5173", "localhost:5174", "orders.arpnetworks.com"
      end
    
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
