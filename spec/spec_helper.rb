# frozen_string_literal: true

# This file was generated by the `rails generate rspec:install` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# The generated `.rspec` file contains `--require spec_helper` which will cause
# this file to always be loaded, without a need to explicitly require it in any
# files.
#
# Given that it is always loaded, you are encouraged to keep this file as
# light-weight as possible. Requiring heavyweight dependencies from this file
# will add to the boot time of your test suite on EVERY test run, even for an
# individual file that may not need all of that loaded. Instead, consider making
# a separate helper file that requires the additional dependencies and performs
# the additional setup, and require it from the spec files that actually need
# it.
#
# The `.rspec` file also contains a few flags that are not defaults but that
# users commonly want.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

require 'knapsack_pro'
require 'simplecov'

# https://knapsackpro.com/faq/question/how-to-use-simplecov-in-queue-mode
KnapsackPro::Hooks::Queue.before_queue do |_queue_id|
  SimpleCov.command_name("rspec_ci_node_#{KnapsackPro::Config::Env.ci_node_index}")
end

KnapsackPro::Adapters::RSpecAdapter.bind

require 'factory_bot'
require 'capybara/rspec'
require 'selenium/webdriver'
require 'webmock/rspec'
require 'support/user_login'
require 'jsonapi/resources/matchers'
require 'aasm/rspec'
require 'rspec/collection_matchers'

# Appear to have to require this explicitly as otherwise receive
# uninitialized constant RSpec::Support::Differ
require 'rspec/support/differ'

require './lib/plate_map_generation'
require './lib/capybara_failure_logger'
require './lib/capybara_timeout_patches'
require 'pry'

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  the_driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)

  # copied the following over from features/support/capybara.rb because I expect it is also relevant here
  the_driver.browser.download_path = DownloadHelpers::PATH.to_s
  the_driver
end

Capybara.register_driver :selenium_chrome do |app|
  driver = Capybara::Selenium::Driver.new(app, browser: :chrome)
  driver.browser.download_path = DownloadHelpers::PATH.to_s
  driver
end

Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
Capybara.default_max_wait_time = 10

WebMock.disable_net_connect!(allow_localhost: true, allow: ['api.knapsackpro.com'])

RSpec.configure do |config|
  config.bisect_runner = :shell # Forking doesn't seem to work

  # rspec-expectations config goes here. You can use an alternate
  # assertion/expectation library such as wrong or the stdlib/minitest
  # assertions if you prefer.
  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4. It makes the `description`
    # and `failure_message` of custom matchers include text for helper methods
    # defined using `chain`, e.g.:
    #     be_bigger_than(2).and_smaller_than(4).description
    #     # => "be bigger than 2 and smaller than 4"
    # ...rather than:
    #     # => "be bigger than 2"
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config goes here. You can use an alternate test double
  # library (such as bogus or mocha) by changing the `mock_with` option here.
  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  # This option will default to `:apply_to_host_groups` in RSpec 4 (and will
  # have no way to turn it off -- the option exists only for backwards
  # compatibility in RSpec 3). It causes shared context metadata to be
  # inherited by the metadata hash of host groups and examples, rather than
  # triggering implicit auto-inclusion in groups with matching metadata.
  config.shared_context_metadata_behavior = :apply_to_host_groups

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    PlateMapGeneration.generate!
    FactoryBot.reload
  end

  # The settings below are suggested to provide a good initial experience
  # with RSpec, but feel free to customize to your heart's content.

  # This allows you to limit a spec run to individual examples or groups
  # you care about by tagging them with `:focus` metadata. When nothing
  # is tagged with `:focus`, all examples get run. RSpec also provides
  # aliases for `it`, `describe`, and `context` that include `:focus`
  # metadata: `fit`, `fdescribe` and `fcontext`, respectively.
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs in order to support
  # the `--only-failures` and `--next-failure` CLI options. We recommend
  # you configure your source control system to ignore this file.
  config.example_status_persistence_file_path = 'spec/examples.txt'

  # Limits the available syntax to the non-monkey patched syntax that is
  # recommended. For more details, see:
  #   - http://rspec.info/blog/2012/06/rspecs-new-expectation-syntax/
  #   - http://www.teaisaweso.me/blog/2013/05/27/rspecs-new-message-expectation-syntax/
  #   - http://rspec.info/blog/2014/05/notable-changes-in-rspec-3/#zero-monkey-patching-mode
  #  config.disable_monkey_patching!

  # Many RSpec users commonly either run the entire suite or an individual
  # file, and it's useful to allow more verbose output when running an
  # individual spec file.
  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  # Print the 10 slowest examples and example groups at the
  # end of the spec run, to help surface which specs are running
  # particularly slow.
  config.profile_examples = 10

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = :random

  config.include UserLogin

  config.around(:each, :warren) do |ex|
    Warren.handler.enable!
    ex.run
    Warren.handler.disable!
  end

  # Add accessioning_enabled to a spec to automatically:
  # - Set accession_samples to true before the test, and roll it back afterward
  # - Configure Accession service with the config defined in spec/data/assession
  # - Ensure accession service configuration is rolled back afterward
  #
  # @example
  #   context 'when accessioning is enabled', accessioning_enabled: true do
  #     it 'suppresses accessioning to allow explicit triggering after upload' do
  #       expect { upload.process(nil) }.not_to change(Delayed::Job, :count)
  #     end
  #   end
  config.around(:each, :accessioning_enabled) do |ex|
    original_value = configatron.accession_samples
    original_config = Accession.configuration
    Accession.configure do |accession|
      accession.folder = File.join('spec', 'data', 'accession')
      accession.load!
    end
    configatron.accession_samples = true
    ex.run
    configatron.accession_samples = original_value
    Accession.configuration = original_config
  end

  config.before do
    # Reset the all sequences at the beginning of each
    # test to reduce the impact test order has on test execution
    FactoryBot.rewind_sequences
  end

  config.before(:each, :js) { page.driver.browser.manage.window.resize_to(1024, 1024) }

  config.after(:each, :js) do |example|
    if example.exception
      name = example.full_description.gsub(/\s/, '_')
      CapybaraFailureLogger.log_failure(name, page)
    end
  end

  # Seed global randomization in this process using the `--seed` CLI option.
  # Setting this allows you to use `--seed` to deterministically reproduce
  # test failures related to randomization by passing the same `--seed` value
  # as the one that triggered the failure.
  Kernel.srand config.seed
end
