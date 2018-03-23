require 'selenium/webdriver'

Capybara.configure do |config|
  config.server = :puma
end

Capybara.save_path = 'tmp/capybara'
Capybara.default_max_wait_time = 10
Capybara.javascript_driver = :selenium_chrome_headless
