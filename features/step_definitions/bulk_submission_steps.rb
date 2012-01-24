def upload_submission_spreadsheet(name)
  attach_file("bulk_submission_spreadsheet", File.join(RAILS_ROOT,'features', 'submission', 'csv', "#{name}.csv"))
  click_button "bulk_submission_submit"
end

When /^I upload a file with (.*) data for (\d+) submissions$/ do |type,number|
  upload_submission_spreadsheet("#{number}_#{type}_rows")
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
  click_button "bulk_submission_submit"
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
