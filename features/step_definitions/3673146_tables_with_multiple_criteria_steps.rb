Given /^I have five requests for "([^\"]*)"$/ do |pipeline_name|
  pipeline = Pipeline.find_by_name(pipeline_name)
  5.times do | index_i |
    request = Given %Q{I have a request for "#{pipeline_name}"}
    request.asset.name = "Test Asset #{index_i}"
    request.asset.save
    request
  end
end

Then /^the table of requests should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#pipeline_inbox tr', 'td,th')))
end
