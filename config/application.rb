require File.expand_path('../boot', __FILE__)

require 'rails/all'
require 'action_dispatch/xml_params_parser'

Bundler.require(:default, Rails.env)

module Sequencescape
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    config.filter_parameters += [:password, :credential_1, :uploaded_data]

    config.assets.prefix = '/public'

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
    # Settings in config/environments/* take precedence over those specified here.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{Rails.root}/extras )
    config.autoload_paths += %W{#{Rails.root}/app/observers}
    config.autoload_paths += %W{#{Rails.root}/app/metal}
    config.autoload_paths += %W{#{Rails.root}/app}
    config.autoload_paths += %W{#{Rails.root}/lib}
    config.autoload_paths += %W{#{Rails.root}/lib/sample_manifest_excel}
    config.autoload_paths += %W{#{Rails.root}/lib/accession}

    config.middleware.insert_after ActionDispatch::ParamsParser, ActionDispatch::XmlParamsParser

    config.encoding = 'utf-8'

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'London'

    # Your secret key for verifying cookie session data integrity.
    # If you change this key, all old sessions will become invalid!
    # Make sure the secret is at least 30 characters and all random,
    # no regular words or you'll be exposed to dictionary attacks.
    # config.action_controller.session = {
    #    :key => '_sequencescape_projects_session',
    #    :secret      => '331126909929cd365e60e61c66e88d260ef609cb813566e03618f6a455dbfc7f50486aa6dc721bcc5fce54455282e3e17bb500f11d8b72bbac369f194c9dae73'
    #  }

    # Enable localisations to be split over multiple paths.
    config.i18n.load_path = Dir[File.join(Rails.root, %w{config locales metadata *.{rb,yml}})]
    I18n.enforce_available_locales = false

    # Jruby 1.7 seems to try and use the http.proxyX settings, but ignores the noProxyHost ENV.
    if defined?(ENV_JAVA)
      ENV_JAVA['http.proxyHost'] = nil
      ENV_JAVA['http.proxyPort'] = nil
      ENV_JAVA['https.proxyHost'] = nil
      ENV_JAVA['https.proxyPort'] = nil
    end
  end
end
