Given /^all of this is happening at exactly "([^\"]+)"$/ do |time_as_string|
  Given %Q{I freeze time at "#{time_as_string}"}
end

Given /^I freeze time at "([^"]*)"$/ do |freeze_point|
  Timecop.freeze(Time.parse(freeze_point))
end

Given /^I travel through time to "([^"]*)"$/ do |destination_time|
  Timecop.travel Time.parse(destination_time)
end

Given /^today's date is "([^"]*)"$/ do |target_date|
  Timecop.travel Date.parse(target_date)
end

Given /^all of this is happening (\d+) hours from now$/ do |hours|
  Timecop.travel(hours.to_i.hours.from_now)
end
