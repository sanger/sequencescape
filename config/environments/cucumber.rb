# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

Sequencescape::Application.configure do
  # Edit at your own peril - it's recommended to regenerate this file
  # in the future when you upgrade to a newer version of Cucumber.

  # IMPORTANT: Setting config.cache_classes to false is known to
  # break Cucumber's use_transactional_fixtures method.
  # For more information see https://rspec.lighthouseapp.com/projects/16211/tickets/165
  config.cache_classes = true
  config.active_record.raise_in_transactional_callbacks = true
  config.active_support.deprecation = :raise

  config.serve_static_files = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true
  config.eager_load = true

  # we don't need :debug unless we're debugging tests
  config.log_level = :error

  # Show full error reports and disable caching
  # config.action_controller.consider_all_requests_local = true
  config.action_controller.perform_caching             = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Avoids threading issues with cucumber and some ajax requests
  # particularly: features/studies/3871492_links_from_study_workflow_view.feature
  # under MRI. If hit to overall test performance is grim, might need to
  # unpick this further.
  # https://github.com/rails/rails/issues/15089
  config.allow_concurrency = false

  config.active_record.observers = [:batch_cache_sweeper, :customer_request_observer]

  if defined?(ENV_JAVA)
    ENV_JAVA['http.proxyHost'] = nil
    ENV_JAVA['http.proxyPort'] = nil
    ENV_JAVA['https.proxyHost'] = nil
    ENV_JAVA['https.proxyPort'] = nil
  end
end
