# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

Sequencescape::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # In the development environment your application's code is reloaded on
  # every request.  This slows down response time but is perfect for development
  # since you don't have to restart the webserver when you make code changes.
  # TODO: Refactor our code to make it easier to set this to false
  # Main issue is it causing problems with nested single table inheritance, such
  # as on plate purpose.
  config.cache_classes = ENV.fetch('CACHE_CLASSES', 'true') == 'true'

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  config.serve_static_files = true
  config.consider_all_requests_local = true

  # Show full error reports and disable caching
  # config.action_controller.consider_all_requests_local = true
  # config.action_view.debug_rjs                         = true
  config.action_controller.perform_caching = false
  config.eager_load = true

  # Temp whilst API / access is finalised
  config.action_controller.allow_forgery_protection = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  config.time_zone = 'London'

  config.active_record.observers = [:customer_request_observer]

  # Set TEST_RABBIT_MQ to enable the amqp_observer for debugging.
  # You'll need a local rabbit MQ server running
  config.active_record.observers << :amqp_observer if ENV['TEST_RABBIT_MQ']
  config.log_level = :debug

  config.active_record.raise_in_transactional_callbacks = true
  config.active_support.deprecation = :raise

  # Use the response timer middleware
  config.middleware.insert_after(ActionController::Failsafe, 'ResponseTimer', File.new(ENV['LOG_TO'], 'w+')) unless ENV['LOG_TO'].nil?

  if ENV['WITH_BULLET'] == 'true'
    config.after_initialize do
      require 'bullet'
      Bullet.enable
      Bullet.alert = ENV['NOISY_BULLET'] == 'true'
      Bullet.bullet_logger
    end
  end
end
