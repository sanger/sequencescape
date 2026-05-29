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

  # Disable Active Record’s asynchronous query execution. By setting it to nil,
  # all database queries will be executed synchronously (in the same thread),
  # rather than using a background thread or pool. This is added to avoid
  # Mysql2::Error: This connection is in use by: #<Fiber:0x0123456789abcdef>
  # errors while running Cucumber tests on CI.
  config.active_record.async_query_executor = nil

  if defined?(ENV_JAVA)
    ENV_JAVA['http.proxyHost'] = nil
    ENV_JAVA['http.proxyPort'] = nil
    ENV_JAVA['https.proxyHost'] = nil
    ENV_JAVA['https.proxyPort'] = nil
  end

  # load WIP features flag
  config.deploy_wip_pipelines = true
end

# Configure Capybara to use Puma in single-threaded mode for tests
# 0 is for min and 1 is for max threads, which effectively makes it single-threaded.
# Silent is to preserve the rails helper setting, which makes the test output less noisy.
Capybara.server = :puma, { Threads: "0:1", Silent: true }
