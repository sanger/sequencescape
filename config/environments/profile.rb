Rails.application.configure do
  # Used for accurately profiling calls.

  # We NEED to cache classes for ruby-rpof
  config.cache_classes = true
  # Eager load on boot
  config.eager_load = true

  # Show full error reports.
  config.consider_all_requests_local = true

  config.cache_template_loading = true

  # Enable/disable caching. By default caching is disabled.
  if Rails.root.join('tmp/caching-dev.txt').exist? #rubocop:disable all
    config.action_controller.perform_caching = true

    config.cache_store = :memory_store
    config.public_file_server.headers = {
      'Cache-Control' => 'public, max-age=172800'
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = true

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  # config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  if ENV['WITH_BULLET'] == 'true'
    config.after_initialize do
      require 'bullet'
      Bullet.enable = true
      Bullet.alert = ENV['NOISY_BULLET'] == 'true'
      Bullet.bullet_logger = true
    end
  end
end
