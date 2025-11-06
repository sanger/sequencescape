# frozen_string_literal: true

require 'simplecov'

ENV['RAILS_ENV'] = 'test'
require File.expand_path("#{File.dirname(__FILE__)}/../config/environment")

require 'minitest/autorun'
require 'shoulda/context'
require 'shoulda/matchers'
require 'rails/test_help'
require 'factory_bot'
require 'webmock/minitest'
require 'knapsack_pro'
knapsack_pro_adapter = KnapsackPro::Adapters::MinitestAdapter.bind
knapsack_pro_adapter.set_test_helper_path(__FILE__)

begin
  require 'pry'
rescue LoadError
  # No pry? That's okay, we're probably on the CI server
end

Dir
  .glob(File.expand_path(File.join(Rails.root, %w[spec factories ** *.rb]))) # rubocop:disable Rails/RootPathnameMethods
  .each { |factory_filename| require factory_filename }

Dir
  .glob(
    File.expand_path(File.join(Rails.root, %w[test shoulda_macros *.rb])) # rubocop:disable Rails/RootPathnameMethods
  )
  .each { |macro_filename| require macro_filename }

require "#{Rails.root}/test/unit/task_test_base"

# Rails.application.load_seed

PlateMapGeneration.generate!

class ActiveSupport::TestCase
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  extend Sanger::Testing::Controller::Macros
  include FactoryBot::Syntax::Methods

  # Transactional fixtures accelerate your tests by wrapping each test method
  # in a transaction that's rolled back on completion.  This ensures that the
  # test database remains unchanged so your fixtures don't have to be reloaded
  # between every test method.  Fewer database queries means faster tests.
  #
  # Read Mike Clark's excellent walkthrough at
  #   http://clarkware.com/cgi/blosxom/2005/10/24#Rails10FastTesting
  #
  # Every Active Record database supports transactions except MyISAM tables
  # in MySQL.  Turn off transactional fixtures in this case; however, if you
  # don't care one way or the other, switching from MyISAM to InnoDB tables
  # is recommended.
  #
  # The only drawback to using transactional fixtures is when you actually
  # need to test transactions.  Since your test is bracketed by a transaction,
  # any transactions started in your code will be automatically rolled back.
  self.use_transactional_tests = false

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  # self.use_instantiated_fixtures = false

  # DON'T...
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  # fixtures :all
  # Fixtures have been deprecated because they are brittle and rubbish.
  # Use Factories and mocks to *explicity* setup what your test requires

  # Used by Quiet Backtrace pluging to reduce testing noise
  # self.backtrace_silencers << :rails_vendor
  # self.backtrace_filters   << :Rails.root
  # Add more helper methods to be used by all tests here...
end

class ActionController::TestCase
  include FactoryBot::Syntax::Methods
  include ApplicationHelper
end

require 'mocha'
require 'minitest/unit'
require 'mocha/minitest'

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end
