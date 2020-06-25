# frozen_string_literal: true

Given /^I have five requests for "([^"]*)"$/ do |pipeline_name|
  pipeline = Pipeline.find_by(name: pipeline_name)
  5.times do |index_i|
    request = step(%Q{I have a request for "#{pipeline_name}"})
    request.asset.labware.name = "Test Asset #{index_i}"
    request.asset.labware.save
    request
  end
end

Then /^the table of requests should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#pipeline_inbox')))
end
