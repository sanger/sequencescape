# frozen_string_literal: true

Given /^all of this is happening at exactly "([^"]+)"$/ do |time_as_string|
  step(%Q{I freeze time at "#{time_as_string}"})
end

Given /^I freeze time at "([^"]*)"$/ do |freeze_point|
  freeze_time = Time.zone.parse(freeze_point)
  travel_to freeze_time
end

After do
  travel_back
end

Given /^I travel through time to "([^"]*)"$/ do |destination_time|
  travel_to Time.zone.parse(destination_time)
end

Given /^today's date is "([^"]*)"$/ do |target_date|
  travel_to Date.parse(target_date)
end
