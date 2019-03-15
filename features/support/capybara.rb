require 'selenium/webdriver'

# Capybara.configure do |config|
#   config.server = :puma
# end

Capybara.register_driver :headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new

  options.add_argument('--headless')
  options.add_argument('--disable_gpu')
  # options.add_argument('--disable-popup-blocking')
  options.add_argument('--window-size=1600,3200')
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.save_path = 'tmp/capybara'
Capybara.default_max_wait_time = 10
Capybara.javascript_driver = ENV.fetch('JS_DRIVER', 'headless_chrome').to_sym

# Cucumber monkey patch
# This is fixed in later versions of cucumber-rails, but we need to upgrade our
# transforms first.
# https://github.com/cucumber/cucumber-rails/commit/286f37fdce0a0e6ea460edd0d26e7bff810ba576#diff-714a52411ebf9e451dcbb01fd9029184
module Cucumber
  module Rails
    module Capybara
      # This is a cucumber module, we re-open it to adjust the click_with_javascript_emulation arguments
      module JavascriptEmulation
        def click_with_javascript_emulation(*)
          if link_with_non_get_http_method?
            ::Capybara::RackTest::Form.new(driver, js_form(element_node.document, self[:href], emulated_method)).submit(self)
          else
            click_without_javascript_emulation
          end
        end
      end
    end
  end
end
