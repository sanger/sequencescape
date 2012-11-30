# Settings specified here will take precedence over those in config/environment.rb

# In the development environment your application's code is reloaded on
# every request.  This slows down response time but is perfect for development
# since you don't have to restart the webserver when you make code changes.
#config.cache_classes = false

# Log error messages when you accidentally call methods on nil.
config.whiny_nils = true

# Show full error reports and disable caching
config.action_controller.consider_all_requests_local = true
config.action_view.debug_rjs                         = true
config.action_controller.perform_caching             = false

# Temp whilst API / access is finalised
config.action_controller.allow_forgery_protection    = false

# Don't care if the mailer can't send
config.action_mailer.raise_delivery_errors = false

config.log_level = :debug

#config.active_record.observers = [ :batch_cache_sweeper, :study_cache_sweeper, :sample_cache_sweeper ]

# Use the response timer middleware
config.middleware.insert_after(ActionController::Failsafe, "ResponseTimer", File.new(ENV['LOG_TO'], 'w+')) unless ENV['LOG_TO'].nil?
