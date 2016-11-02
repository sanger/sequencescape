require 'capybara/poltergeist'
Capybara.save_path = 'tmp/capybara'
Capybara.default_max_wait_time = 10
Capybara.javascript_driver = :poltergeist
