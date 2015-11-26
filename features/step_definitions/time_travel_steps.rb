#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
Given /^all of this is happening at exactly "([^\"]+)"$/ do |time_as_string|
  step(%Q{I freeze time at "#{time_as_string}"})
end

Given /^I freeze time at "([^\"]*)"$/ do |freeze_point|
  freeze_time = Time.parse(freeze_point)
  Timecop.freeze(freeze_time)
end

Given /^I travel through time to "([^\"]*)"$/ do |destination_time|
  Timecop.travel Time.parse(destination_time)
end

Given /^today's date is "([^"]*)"$/ do |target_date|
  Timecop.travel Date.parse(target_date)
end

Given /^all of this is happening (\d+) hours from now$/ do |hours|
  Timecop.travel(hours.to_i.hours.from_now)
end
