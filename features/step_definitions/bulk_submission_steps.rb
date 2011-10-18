When /^I upload a file with (.*) data for (\d+) submissions$/ do |type,number|
  filename = "#{number}_#{type}_rows.csv"
  attach_file("bulk_submission_spreadsheet", File.join(RAILS_ROOT,'features', 'submission', 'csv', filename))
  click_button "bulk_submission_submit"
end

When /^I upload an empty file$/ do
  filename = "no_rows.csv"
  attach_file("bulk_submission_spreadsheet", File.join(RAILS_ROOT,'features', 'submission', 'csv', filename))
  click_button "bulk_submission_submit"
end
When /^I submit an empty form$/ do
  click_button "bulk_submission_submit"
end

When /^I upload a file with an invalid header row$/ do
  filename = "bad_header.csv"
  attach_file("bulk_submission_spreadsheet", File.join(RAILS_ROOT,'features', 'submission', 'csv', filename))
  click_button "bulk_submission_submit"
end