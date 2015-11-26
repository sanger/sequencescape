#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013 Genome Research Ltd.
Sequencescape::Application.configure do
  # Settings specified here will take precedence over those in config/environment.rb

  # The test environment is used exclusively to run your application's
  # test suite.  You never need to work with it otherwise.  Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs.  Don't rely on the data there!
  config.cache_classes = true
  config.active_support.deprecation = :log

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # we don't need :debug unless we're debugging tests
  config.log_level = :warn

  # Show full error reports and disable caching
  # config.action_controller.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Rails 4 provides much more sensible protection
  config.active_record.whitelist_attributes = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test
  config.reload_plugins = true

  config.time_zone = 'London'


  #config.active_record.observers = [ :batch_cache_sweeper, :request_observer ]
  config.active_record.observers = [ :request_observer ]
end
