require 'capybara/poltergeist'
Capybara.save_and_open_page_path = 'tmp/capybara'
Capybara.default_max_wait_time = 5

# Capybara.register_driver :poltergeist_debug do |app|
#   Capybara::Poltergeist::Driver.new(app, :inspector => true)
# end

Capybara.javascript_driver = :poltergeist
