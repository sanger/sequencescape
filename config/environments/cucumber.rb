# frozen_string_literal: true
Rails.application.configure do
  # Edit at your own peril - it's recommended to regenerate this file
  # in the future when you upgrade to a newer version of Cucumber.

  # cache_classes = false is required for ajax requests to be handled correctly
  # See https://chrisortman.com/2015/03/27/ajax-race-condition-in-cucumber/
  config.cache_classes = false
  config.active_support.deprecation = :log

  config.public_file_server.enabled = true

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true
  config.eager_load = true

  # we don't need :debug unless we're debugging tests
  config.log_level = :error

  # Show full error reports and disable caching
  # config.action_controller.consider_all_requests_local = true
  config.action_controller.perform_caching = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  config.disable_animations = true

  # Avoids threading issues with cucumber and some ajax requests
  # particularly: features/studies/3871492_links_from_study_workflow_view.feature
  # under MRI. If hit to overall test performance is grim, might need to
  # unpick this further.
  # https://github.com/rails/rails/issues/15089
  config.allow_concurrency = false

  if defined?(ENV_JAVA)
    ENV_JAVA['http.proxyHost'] = nil
    ENV_JAVA['http.proxyPort'] = nil
    ENV_JAVA['https.proxyHost'] = nil
    ENV_JAVA['https.proxyPort'] = nil
  end

  # load WIP features flag
  config.deploy_wip_pipelines = true
end
