require_relative 'boot'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sequencescape
  class Application < Rails::Application # rubocop:todo Style/Documentation
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0
    # Default options which predate the Rails 5 switch
    config.active_record.belongs_to_required_by_default = false
    config.action_controller.forgery_protection_origin_check = false
    config.action_controller.per_form_csrf_tokens = false

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
    config.logger = Logger.new(Rails.root.join('log', Rails.env + '.log'), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    config.filter_parameters += %i[password credential_1 uploaded_data]

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
    config.autoload_paths += %W{#{Rails.root}/lib/accession}

    config.encoding = 'utf-8'

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'London'

    config.warren = config_for(:warren)

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

    config.cherrypickable_default_type = 'ABgene_0800'
    config.plate_default_type = 'ABgene_0800'
    config.plate_default_max_volume = 180
    # See issue #3134 Leave wells D3/H10 free
    config.plate_default_control_wells_to_leave_free = [19, 79].freeze

    config.aker = config_for(:aker).with_indifferent_access
    config.phi_x = config_for(:phi_x).with_indifferent_access

    config.generators do |g|
      g.test_framework :rspec,
                       fixtures: true,
                       view_specs: false,
                       helper_specs: false,
                       routing_specs: false,
                       controller_specs: false,
                       request_specs: true
      g.fixture_replacement :factory_bot, dir: 'spec/factories'
    end

    config.ets_enabled = false
    config.disable_animations = false

    # Rails 5

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get post options patch], credentials: false
      end
    end
  end
end
