Then /^the bait library index page should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#bait_library_list tr', 'td,th')))
end
