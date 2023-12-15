# frozen_string_literal: true

require 'selenium/webdriver'
require 'capybara'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  the_driver = Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)

  # the following is needed to avoid a test failure where the driver would
  # forget / ignore its configured download location on every other run
  the_driver.browser.download_path = DownloadHelpers::PATH.to_s if the_driver.browser.respond_to?(:download_path=)
  the_driver
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
