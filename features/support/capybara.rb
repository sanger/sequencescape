# frozen_string_literal: true

require 'webdrivers/chromedriver'
require 'selenium/webdriver'
require 'capybara'

Webdrivers::Chromedriver.update

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  driver = Capybara.drivers[:selenium_chrome_headless].call(app)

  configure_window_size(driver)
  enable_chrome_headless_downloads(driver)
end

def configure_window_size(driver)
  # links in header disappear if window is too small, then capybara can't click on them
  driver.options[:options].add_argument('--window-size=1600,3200')
end

def enable_chrome_headless_downloads(driver)
  driver.options[:options].add_preference(:download, default_directory: Capybara.save_path)
  driver.browser.download_path = Capybara.save_path
  driver
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym
