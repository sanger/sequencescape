require 'selenium/webdriver'

Capybara.configure do |config|
  config.server = :puma
end

Capybara.javascript_driver = :selenium_chrome_headless
