ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
#TODO: for rails 3 replace with rails/test_help
require "test_help"

require File.expand_path(File.join(Rails.root, %w{test factories.rb}))
 Dir.glob(File.expand_path(File.join(Rails.root, %w{test factories ** *.rb}))) do |factory_filename|
   require factory_filename
 end

require "#{Rails.root}/test/unit/task_test_base"

# add the ci_reporter to create reports for test-runs, since parallel_tests is not invoked through rake
if ENV.has_key?("CI")
  require 'ci/reporter/test_unit' # needed, despite "bundle exec"!
  # Intercepts mediator creation in ruby-test >= 2.1
  module Test #:nodoc:all
    module Unit
      module UI
        class TestRunner
          def setup_mediator
            # swap in our custom mediator
            @mediator = CI::Reporter::TestUnit.new(@suite)
          end
        end
      end
    end
  end
end

class ActiveSupport::TestCase
  extend Sanger::Testing::Controller::Macros
  extend Sanger::Testing::View::Macros
  extend Sanger::Testing::Model::Macros

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
  #fixtures :all
  # Fixtures have been deprecated because they are brittle and rubbish.
  # Use Factories and mocks to *explicity* setup what your test requires

  # Used by Quiet Backtrace pluging to reduce testing noise
  #self.backtrace_silencers << :rails_vendor
  #self.backtrace_filters   << :rails_root
  # Add more helper methods to be used by all tests here...
end

# Adds support for a setup and teardown method across a set of tests, meaning that expensive DB
# operations can be done once.  Please note that you are responsible for tidying up after yourself,
# don't rely on a transaction doing it for you!
class ActiveSupport::TestCase
  class << self
    # Called at the start of a group of tests.
    def startup
      # Does nothing
    end

    # Called at the end of a group of tests.  You must manage your exception handling yourself
    # and not raise any out of this method.
    def shutdown
      # Does nothing
    end

    def suite #:nodoc:
      test_suite = super
      test_suite.instance_variable_set('@test_class', self)
      class << test_suite
        def run(*args, &block)
          @test_class.startup
          super
        ensure
          @test_class.shutdown
        end
      end
      test_suite
    end
  end
end
