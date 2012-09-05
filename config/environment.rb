# Be sure to restart your server when you modify this file

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.11' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here.
  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory are automatically loaded.
  # See Rails::Configuration for more options.

  # Skip frameworks you're not going to use. To use Rails without a database
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Specify gems that this application depends on.
  # They can then be installed with "rake gems:install" on new installations.
  #config.gem "configatron"
  #config.gem "ruby-net-ldap", :lib => "net/ldap"
  #config.gem "soap4r", :lib => "soap/soap"
  #config.gem "will_paginate", :lib => "will_paginate"
  #config.gem "rubyist-aasm", :lib => "aasm", :source => "http://gems.github.com"
  #config.gem "parseexcel"
  #config.gem "curb"
  #config.gem "ar-extensions"

  # Testing focused - best placed here for easy gem management
  #config.gem "test-unit", :lib => "test/unit"
  #config.gem "thoughtbot-shoulda", :lib => "shoulda", :source => 'http://gems.github.com'
  #config.gem "factory_girl", :lib => "factory_girl", :source => "http://gems.github.com"
  #config.gem 'db-charmer', :lib => 'db_charmer', :source => 'http://gemcutter.org'
  #config.gem 'mexpolk-flow_pagination', :lib => 'flow_pagination'

  # Only load the plugins named here, in the order given. By default, all plugins
  # in vendor/plugins are loaded in alphabetical order.
  # :all can be used as a placeholder for all plugins not explicitly named
  #config.plugins = [ "rails-authorization-plugin".to_sym, :all ]

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )
  config.autoload_paths += %W{ #{RAILS_ROOT}/app/observers }
  config.autoload_paths += %W{ #{Rails.root}/app/api }

  # UPDATE ? - Is this old rails code or custom code?
  # if %w(development test sandbox production cucumber).include? Rails.env
  #   config.load_paths += Dir["#{Rails.root}/vendor/gems/**"].map do |dir|
  #     File.directory?(lib = "#{dir}/lib") ? lib : dir
  #   end
  # end

  # Make Time.zone default to the specified zone, and make Active Record store time values
  # in the database in UTC, and return them converted to the specified local zone.
  # Run "rake -D time" for a list of tasks for finding time zone names. Uncomment to use default local time.
  config.time_zone = 'London'

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  # Make sure the secret is at least 30 characters and all random,
  # no regular words or you'll be exposed to dictionary attacks.
  config.action_controller.session = {
     :key => '_sequencescape_projects_session',
     :secret      => '331126909929cd365e60e61c66e88d260ef609cb813566e03618f6a455dbfc7f50486aa6dc721bcc5fce54455282e3e17bb500f11d8b72bbac369f194c9dae73'
   }

  config.reload_plugins = true

  # Enable localisations to be split over multiple paths.
  config.i18n.load_path << Dir[File.join(Rails.root, %w{config locales metadata *.{rb,yml}})]

  # Use the database for sessions instead of the cookie-based default,
  # which shouldn't be used to store highly confidential information
  # (create the session table with "rake db:sessions:create")
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql
end
