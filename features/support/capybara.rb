# frozen_string_literal: true

require 'selenium/webdriver'
require 'capybara'
require './spec/support/select_helper'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new

  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  # options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--disable-search-engine-choice-screen')
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_firefox').to_sym
