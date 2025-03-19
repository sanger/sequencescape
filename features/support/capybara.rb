# frozen_string_literal: true

require 'selenium/webdriver'
require 'capybara'
require_relative 'capybara_failure_logger'
require_relative 'capybara_timeout_patch'
require_relative 'capybara_select2_patch'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new

  options.add_preference('browser.download.folderList', 2) # Use custom download path (set via browser.download.dir)
  options.add_preference('browser.download.dir', DownloadHelpers::PATH.to_s) # Sets the custom directory for downloads.

  # Add relevant MIME types that Firefox will automatically download without showing a prompt
  options.add_preference('browser.helperApps.neverAsk.saveToDisk', 'application/pdf,text/csv,application/octet-stream')

  options.add_preference('pdfjs.disabled', true) # Disable Firefox’s built-in PDF viewer

  options.add_argument('--window-size=1600,3200')
  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)
  # options.add_argument('--headless')
  options.add_argument('--disable-gpu')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-search-engine-choice-screen')
  Capybara::Selenium::Driver.new(app, browser: :firefox, options: options)
end

Capybara.register_driver :firefox do |app|
  options = Selenium::WebDriver::Firefox::Options.new

  options.add_preference('browser.download.folderList', 2) # Use custom download path (set via browser.download.dir)
  options.add_preference('browser.download.dir', DownloadHelpers::PATH.to_s) # Sets the custom directory for downloads.

  # Add relevant MIME types that Firefox will automatically download without showing a prompt
  options.add_preference('browser.helperApps.neverAsk.saveToDisk', 'application/pdf,text/csv,application/octet-stream')

  options.add_preference('pdfjs.disabled', true) # Disable Firefox’s built-in PDF viewer

  options.add_preference('download.default_directory', DownloadHelpers::PATH.to_s)

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Selenium::WebDriver.logger.ignore(:clear_local_storage, :clear_session_storage)

Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_firefox').to_sym
