# frozen_string_literal: true
require_relative 'boot'
# We don't use:
# require 'rails/all'
# Instead we only load the components we need. When updating rails versions you can
# checkout the contents of https://github.com/rails/rails/blob/main/railties/lib/rails/all.rb
# to find out what's included by default.
require 'active_record/railtie'
require 'active_storage/engine'
require 'action_controller/railtie'
require 'action_view/railtie'
require 'action_mailer/railtie'
require 'active_job/railtie'
require 'action_cable/engine'
require 'action_mailbox/engine'
require 'action_text/engine'
require 'rails/test_unit/railtie'
# require 'sprockets/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sequencescape
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.autoloader = :classic

    # Default options which predate the Rails 5 switch
    config.active_record.belongs_to_required_by_default = false
    config.action_controller.forgery_protection_origin_check = false
    config.action_controller.per_form_csrf_tokens = false

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = 'utf-8'

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]
    config.logger = Logger.new(Rails.root.join('log', Rails.env + '.log'), 5, 10 * 1024 * 1024)
    config.logger.formatter = ::Logger::Formatter.new

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    config.filter_parameters += %i[password credential_1 uploaded_data]

    # Settings in config/environments/* take precedence over those specified here.

    # Add additional load paths for your own custom dirs
    # config.load_paths += %W( #{Rails.root}/extras )
    config.autoload_paths += %W[#{Rails.root}/app/observers]
    config.autoload_paths += %W[#{Rails.root}/app/metal]
    config.autoload_paths += %W[#{Rails.root}/app]
    config.autoload_paths += %W[#{Rails.root}/lib]
    config.autoload_paths += %W[#{Rails.root}/lib/accession]

    config.encoding = 'utf-8'

    # Make Time.zone default to the specified zone, and make Active Record store time values
    # in the database in UTC, and return them converted to the specified local zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
    config.time_zone = 'London'

    # Enable localisations to be split over multiple paths.
    config.i18n.load_path = Dir[File.join(Rails.root, %w[config locales metadata *.{rb,yml}])] # rubocop:disable Rails/RootPathnameMethods
    I18n.enforce_available_locales = false

    config.cherrypickable_default_type = 'ABgene_0800'
    config.plate_default_type = 'ABgene_0800'
    config.plate_default_max_volume = 180

    # See issue #3134 Leave wells D3/H10 free
    config.plate_default_control_wells_to_leave_free = [19, 79].freeze

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

    config.disable_animations = ENV.fetch('DISABLE_ANIMATIONS', false).present?

    # Rails 5

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: %i[get post options patch], credentials: false
      end
    end

    # end Rails 5 #

    # Fix for Psych::DisallowedClass: Tried to load unspecified class
    # this has to be in "after_initialize" because we need custom classes to be loaded already
    config.after_initialize do
      ActiveRecord::Base.yaml_column_permitted_classes = [
        Symbol,
        ActiveSupport::HashWithIndifferentAccess,
        HashWithIndifferentAccess, # rubocop:disable Rails/TopLevelHashWithIndifferentAccess
        RequestType::Validator::ArrayWithDefault,
        RequestType::Validator::LibraryTypeValidator,
        RequestType::Validator::FlowcellTypeValidator,
        ActionController::Parameters,
        Set,
        Range,
        FieldInfo,
        Time
      ]
    end
  end
end
