# frozen_string_literal: true
Rails.application.configure do
  # Used for accurately profiling calls.

  # We NEED to cache classes for ruby-rpof
  config.cache_classes = true

  # Eager load on boot
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = false

  config.cache_template_loading = true

  config.action_controller.perform_caching = true
  ActionController::Base.cache_store = :file_store, 'tmp/cache'

  config.action_controller.allow_forgery_protection = false

  config.assets.digest = true

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker
end
