# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^([1-9]|[1-9]\d+) pending delayed jobs are processed$/ do |count|
  Delayed::Worker.new(quiet: ENV['LOUD_DELAYED_JOBS'].nil?).work_off(count.to_i)
  errors = Delayed::Job.all.map { |j| j.run_at? && j.last_error }.reject(&:blank?)
  raise StandardError, "Delayed jobs have failed #{errors.to_yaml}" if errors.present?
  raise StandardError, "There are #{Delayed::Job.count} jobs left to process" unless Delayed::Job.count.zero?
end

Given /^all pending delayed jobs (?:are|have been) processed$/ do
  count = Delayed::Job.count
  raise StandardError, 'There are no delayed jobs to process!' if count.zero?
  step("#{count} pending delayed jobs are processed")
end

Then /^I should have (\d+) delayed jobs with a priority of (\d+)$/ do |number, priority|
  assert_equal(number.to_i, Delayed::Job.count(conditions: { priority: priority }))
end

Then /^the last delayed job should have a priority of (\d+)$/ do |priority|
  assert_equal(priority.to_i, Delayed::Job.last.priority)
end

Then /^there should be no delayed jobs to be processed$/ do
  assert_equal(0, Delayed::Job.count, 'there are delayed jobs to be processed')
end
