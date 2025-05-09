# frozen_string_literal: true

require 'selenium/webdriver'
require 'capybara'
require 'capybara/cuprite'
require_relative 'capybara_failure_logger'
require_relative 'capybara_timeout_patch'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-search-engine-choice-screen')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver(:cuprite) do |app|
  Capybara::Cuprite::Driver.new(
    app,
    window_size: [1200, 800],
    process_timeout: 30,
    browser_options: {
      'no-sandbox': nil
    }
  )
end

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'cuprite').to_sym
