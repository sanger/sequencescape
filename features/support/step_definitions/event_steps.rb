
Then /^the events table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#events')))
end
