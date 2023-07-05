# frozen_string_literal: true

require 'webdrivers/chromedriver'
require 'selenium/webdriver'
require 'capybara'

Webdrivers::Chromedriver.update

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH)
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
