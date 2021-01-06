# frozen_string_literal: true

require 'simplecov'
# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

ENV['RAILS_ENV'] ||= 'cucumber'

if ENV['RAILS_ENV'] != 'cucumber'
  puts "You are running the cucumber specs with the #{ENV['RAILS_ENV']} environment."
  puts "This can cause problems with gem loading. Please use 'cucumber' instead."
end

require 'cucumber/rails'
require 'factory_bot_rails'

require_relative 'capybara'
require_relative 'parameter_types'
# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how
# your application behaves in the production environment, where an error page will
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise 'You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it.'
end

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
# We're using a gem to try and improve the robustness of this
# https://github.com/iangreenleaf/transactional_capybara
Cucumber::Rails::Database.javascript_strategy = :transaction
require 'transactional_capybara'
TransactionalCapybara.share_connection

World(MultiTest::MinitestWorld)
MultiTest.disable_autorun

After('@javascript') do
  # See https://github.com/iangreenleaf/transactional_capybara
  TransactionalCapybara::AjaxHelpers.wait_for_ajax(page)
end

After do |scenario|
  if scenario.failed?
    name = scenario.name.parameterize
    if page.respond_to?(:save_screenshot)
      begin
        page.save_screenshot("#{name}.png")
        log "📸 Screenshot saved to #{Capybara.save_path}/#{name}.png"
      rescue Capybara::NotSupportedByDriverError
        # Do nothing
      end
    end
    if page.respond_to?(:save_page)
      page.save_page("#{name}.html")
      log "📐 HTML saved to #{Capybara.save_path}/#{name}.html"
    end
    if page.driver.browser.respond_to?(:manage)
      errors = page.driver.browser.manage.logs.get(:browser)
      log '== JS errors ============'
      errors.each do |jserror|
        log jserror.message
      end
      log '========================='
    end
  end
end
