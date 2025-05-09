# frozen_string_literal: true

selected_env = ENV['RAILS_ENV'] ||= 'cucumber'

if selected_env != 'cucumber'
  puts "You are running the cucumber specs with the #{selected_env} environment."
  puts "This can cause problems with gem loading. Please use 'cucumber' instead."
end
