# frozen_string_literal: true

require 'simplecov'
require 'spec_helper'
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'rspec/rails'
# Add additional requires below this line. Rails is not loaded until this point!

require 'rspec/json_expectations'

require 'support/api_helper'

require 'shared_contexts/it_requires_login'
require 'shared_contexts/shared_io_examples'
require 'shoulda/matchers'
require 'rspec/longrun'

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Dir[Rails.root.join('spec/support/**/*.rb')].each { |f| require f }

# Added with rails 6 update, the problem almost certainly exists elsewhere.
ActiveRecord::Base.connection.reconnect!
# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip # rubocop:disable RSpec/Output
  exit 1
end

RSpec.configure do |config|
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
  config.include ApiHelper
  config.include TableHelper

  # In a few places we have models that receive a file from an uploader
  # fixture_file_upload() ensures that the tests mimic the live behaviour.
  # This include make sit available to us. Including it globally causes
  # issues eleswhere
  config.include ActionDispatch::TestProcess, with: :uploader
  config.include ActiveSupport::Testing::TimeHelpers

  config.include Rails.application.routes.url_helpers

  config.include ApiV2Helper, with: :api_v2
  config.include ApiV2AttributeMatchers
  config.include ApiV2RelationshipMatchers
  config.include RSpec::Longrun::DSL

  Capybara.add_selector(:data_behavior) { xpath { |name| XPath.css("[data-behavior='#{name}']") } }

  Capybara.server = :puma, { Silent: true }
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    # Choose a test framework:
    with.test_framework :rspec
    with.library :rails
  end
end

ActionView::TestCase::TestController.include AuthenticatedSystem
