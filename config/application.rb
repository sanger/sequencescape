# frozen_string_literal: true

require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sequencescape
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Default options which predate the Rails 5 switch
    # Due to loading order, set these here and not in an initializer, see https://github.com/rails/rails/issues/23589
    config.active_record.belongs_to_required_by_default = false
    config.action_controller.forgery_protection_origin_check = false
    config.action_controller.per_form_csrf_tokens = false

    # Enable YJIT by default if running Ruby 3.3+
    # YJIT is Ruby's JIT compiler that is available in CRuby since Ruby 3.1. It can provide significant performance improvements for Rails applications, offering 15-25% latency improvements.
    # In Rails 7.2, YJIT is enabled by default if running Ruby 3.3 or newer.
    # You can disable YJIT by setting:
    Rails.application.config.yjit = false

    # Sets the exceptions application invoked by the ShowException middleware when an exception happens.
    config.exceptions_app = routes

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.logger = Logger.new(Rails.root.join('log', "#{Rails.env}.log"), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.filter_parameters += %i[password credential_1 uploaded_data]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #

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

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'London'

    # Enable localisations to be split over multiple paths.
    config.i18n.load_path = Dir[File.join(Rails.root, %w[config locales metadata *.{rb,yml}])] # rubocop:disable Rails/RootPathnameMethods
    I18n.enforce_available_locales = false

    ###
    # Adds image/webp to the list of content types Active Storage considers as an image
    # Prevents automatic conversion to a fallback PNG, and assumes clients support WebP,
    # as they support gif, jpeg, and png.
    # This is possible due to broad browser support for WebP, but older browsers and
    # email clients may still not support WebP.
    # Requires imagemagick/libvips built with WebP support.
    #++
    Rails.application.config.active_storage.web_image_content_types = %w[image/png image/jpeg image/gif]

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
  end
end
