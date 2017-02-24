# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.

require 'simplecov'

ENV['RAILS_ENV'] = 'test'
require File.expand_path(File.dirname(__FILE__) + '/../config/environment')

require 'minitest/autorun'
require 'shoulda'
require 'rails/test_help'
require 'factory_girl'
require 'webmock/minitest'

begin
  require 'pry'
rescue LoadError
  # No pry? That's okay, we're probably on the CI server
end

require File.expand_path(File.join(Rails.root, %w{test factories.rb}))
Dir.glob(File.expand_path(File.join(Rails.root, %w{test factories ** *.rb}))) do |factory_filename|
 require factory_filename
end
Dir.glob(File.expand_path(File.join(Rails.root, %w{test lib sample_manifest_excel factories ** *.rb}))) do |factory_filename|
 require factory_filename
end

Dir.glob(File.expand_path(File.join(Rails.root, %w{test shoulda_macros *.rb}))) do |macro_filename|
  require macro_filename
end

require "#{Rails.root}/test/unit/task_test_base"

# Rails.application.load_seed

class ActiveSupport::TestCase
  extend Sanger::Testing::Controller::Macros
  extend Sanger::Testing::View::Macros
  extend Sanger::Testing::Model::Macros
  include FactoryGirl::Syntax::Methods

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
  self.use_transactional_fixtures = true

  # Instantiated fixtures are slow, but give you @david where otherwise you
  # would need people(:david).  If you don't want to migrate your existing
  # test cases which use the @david style and don't mind the speed hit (each
  # instantiated fixtures translates to a database query per test method),
  # then set this back to true.
  self.use_instantiated_fixtures  = false

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
  include FactoryGirl::Syntax::Methods
end

require 'mocha'
require 'minitest/unit'
require 'mocha/mini_test'
