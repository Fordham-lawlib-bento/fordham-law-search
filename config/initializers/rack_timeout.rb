# Effectively no timeout in development please, so we can debug and take our time
Rack::Timeout.timeout = Rails.env.development? ? 10000 : 20  # seconds
