# frozen_string_literal: true

require_relative '../../lib/deployed'
require_relative '../../app/middleware/request_logger'

Rails.application.configure do
  # Insert RequestLogger near the top, before Rails::Rack::Logger
  config.middleware.insert_before(Rails::Rack::Logger, RequestLogger)
end

# Add backtrace silencers for middleware so that we don't see it in backtraces.
Rails.backtrace_cleaner.add_silencer { |line| line.include?('request_logger') }
