#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

def upload_submission_spreadsheet(name)
  attach_file("bulk_submission_spreadsheet", File.join(Rails.root,'features', 'submission', 'csv', "#{name}.csv"))
  click_button "Create Bulk submission"
end

When /^I upload a file with (.*) data for (\d+) submissions$/ do |type,number|
  upload_submission_spreadsheet("#{number}_#{type}_rows")
end

When /^I upload a file with valid data for 1 tube submissions$/ do
  upload_submission_spreadsheet("1_tube_submission")
end

When /^I upload a file with 2 valid SC submissions$/ do
  upload_submission_spreadsheet("2_valid_sc_submissions")
end

When /^I upload a file with 1 invalid submission and 1 valid submission$/ do
  upload_submission_spreadsheet("1_valid_1_invalid")
end

When /^I upload an empty file$/ do
  upload_submission_spreadsheet("no_rows")
end

When /^I submit an empty form$/ do
  click_button "Create Bulk submission"
end

When /^I upload a file with an invalid header row$/ do
  upload_submission_spreadsheet("bad_header")
end

Then /^there should be no submissions$/ do
  assert_equal(0, Submission.count, "There should have been no submissions")
end

Then /^there should be an order with the bait library name set to "([^\"]+)"$/ do |name|
  assert_not_nil(
    Order.all.detect { |o| o.request_options[:bait_library_name] == name },
    "There is no order with the bait library name set to #{name.inspect}"
  )
end

Then /^there should be an order with the gigabases expected set to "(.*?)"$/ do |gigabase|
    assert_not_nil(
    Order.all.detect { |o| o.request_options['gigabases_expected'] == gigabase },
    "There is no order with the gigabases expected set to #{gigabase}"
  )
end

Then /^the last submission should contain two assets$/ do
  assert_equal 2, Submission.last.orders.reduce(0) {|total,order| total + order.assets.count }
end

Then /^the last submission should contain the tube with barcode "(.*?)"$/ do |barcode|
  assert Submission.last.orders.reduce([]) {|assets,order| assets.concat(order.assets) }.detect {|a| a.barcode == barcode}
end
