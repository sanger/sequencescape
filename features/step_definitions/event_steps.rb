Then /^the events table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#events tr', 'td,th')))
end
