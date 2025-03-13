# frozen_string_literal: true

require 'selenium/webdriver'
require 'capybara'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-search-engine-choice-screen')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
