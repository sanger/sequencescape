# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

Sequencescape::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true

  # Currently, Active Record suppresses errors raised within `after_rollback`/`after_commit`
  # callbacks and only print them to the logs. In the next version, these errors will no
  # longer be suppressed. Instead, the errors will propagate normally just like in other
  # Active Record callbacks.
  config.active_record.raise_in_transactional_callbacks = true
  config.active_support.deprecation = :raise
  config.active_support.test_order = :random

  config.serve_static_files = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true
  config.eager_load = true

  # we don't need :debug unless we're debugging tests
  config.logger = Logger.new(STDOUT) if ENV.fetch('LOG_TO_CONSOLE', false)
  config.log_level = ENV.fetch('LOG_LEVEL', :error)

  # Show full error reports and disable caching
  # config.action_controller.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.time_zone = 'London'

  # Avoids threading issues with cucumber and some ajax requests
  # particularly: features/studies/3871492_links_from_study_workflow_view.feature
  # under MRI. If hit to overall test performance is grim, might need to
  # unpick this further.
  # https://github.com/rails/rails/issues/15089
  config.allow_concurrency = false

  # config.active_record.observers = [ :batch_cache_sweeper, :request_observer ]
  config.active_record.observers = [:customer_request_observer]
end
