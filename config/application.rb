# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sequencescape
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Sets the exceptions application invoked by the ShowException middleware when an exception happens.
    config.exceptions_app = routes

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.logger = Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.filter_parameters += %i[password credential_1 uploaded_data]

    # Settings in config/environments/* take precedence over those specified here.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{Rails.root}/extras )
    config.autoload_paths += %W[#{Rails.root}/app]
    config.autoload_paths += %W[#{Rails.root}/lib]
    config.autoload_paths += %W[#{Rails.root}/lib/accession]

    config.eager_load_paths += %W[#{Rails.root}/app]
    config.eager_load_paths += %W[#{Rails.root}/lib]
    config.eager_load_paths += %W[#{Rails.root}/lib/accession]

    # Some lib files we don't want to autoload as they are not required in the rails app
    %w[generators informatics].each { |file| Rails.autoloaders.main.ignore(Rails.root.join("lib/#{file}")) }

    # Eager load when running rake tasks. This ensures our STI classes are loaded, required for record loader
    # To correctly access all purpose types
    config.rake_eager_load = true

    # Load the custom inflections to help with the AASM module
    Rails.autoloaders.main.inflector.inflect('aasm' => 'AASM')

    config.encoding = 'utf-8'

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'London'

    # Enable localisations to be split over multiple paths.
    config.i18n.load_path = Dir[File.join(Rails.root, %w[config locales metadata *.{rb,yml}])] # rubocop:disable Rails/RootPathnameMethods
    I18n.enforce_available_locales = false
    # TODO: move these to a config/initializers/something.rb file...

    config.cherrypickable_default_type = 'ABgene_0800'
    config.plate_default_type = 'ABgene_0800'
    config.plate_default_max_volume = 180

    # See issue #3134 Leave wells D3/H10 free
    config.plate_default_control_wells_to_leave_free = [19, 79].freeze

    config.phi_x = config_for(:phi_x).with_indifferent_access

    # add ena requirement fields here
    config.ena_requirement_fields = config_for(:ena_requirement_fields)

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

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
