# frozen_string_literal: true
Rails.application.configure do
  # Configure 'rails notes' to inspect Cucumber files
  config.annotations.register_directories('features')
  config.annotations.register_extensions('feature') { |tag| /#\s*(#{tag}):?\s*(.*)$/ }

  # Settings specified here will take precedence over those in config/application.rb.

  # Support requests coming from other Docker containers on localhost.
  config.hosts << 'host.docker.internal'

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = ENV.fetch('CACHE_CLASSES', 'true') == 'true'

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp/caching-dev.txt').exist?
    config.action_controller.perform_caching = true
    config.action_controller.enable_fragment_cache_logging = true

    config.cache_store = :memory_store
    config.public_file_server.headers = { 'Cache-Control' => "public, max-age=#{2.days.to_i}" }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Store uploaded files on the local file system (see config/storage.yml for options).
  config.active_storage.service = :local

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
  config.logger = ActiveSupport::Logger.new($stdout) if ENV['RAILS_LOG_TO_FILE'].blank?
  # config.log_level = ENV.fetch('LOG_LEVEL', :debug).to_sym
  config.log_level = :error
  # Raise an error on page load if there are pending migrations.
  # Disable this if we're pointing at a custom database url
  custom_db = ENV.fetch('DATABASE_URL', nil).present?
  config.active_record.migration_error = custom_db ? false : :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  use_polling_file_watcher = ENV.fetch('USE_POLLING_FILE_WATCHER', 'false') == 'true'
  polling_file_watcher = ActiveSupport::FileUpdateChecker
  evented_file_watcher = ActiveSupport::EventedFileUpdateChecker
  config.file_watcher = use_polling_file_watcher ? polling_file_watcher : evented_file_watcher

  config.after_initialize do
    Bullet.enable = ENV['WITH_BULLET'] == 'true'
    Bullet.alert = ENV['NOISY_BULLET'] == 'true'
    Bullet.bullet_logger = true
    Bullet.rails_logger = true
  end

  # load WIP features flag
  config.deploy_wip_pipelines = true
end

Rack::MiniProfiler.config.position = 'right'
