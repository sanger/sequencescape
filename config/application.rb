require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sequencescape
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1


    # Load the custom inflections to help with the AASM module
    Rails.autoloaders.main.inflector.inflect('aasm' => 'AASM')

    # TODO: move these to a config/initializers/something.rb file...

    config.cherrypickable_default_type = 'ABgene_0800'
    config.plate_default_type = 'ABgene_0800'
    config.plate_default_max_volume = 180

    # See issue #3134 Leave wells D3/H10 free
    config.plate_default_control_wells_to_leave_free = [19, 79].freeze

    config.phi_x = config_for(:phi_x).with_indifferent_access

    # add ena requirement fields here
    config.ena_requirement_fields = config_for(:ena_requirement_fields)

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
