Given /^sample "([^\"]+)" is in a sample tube named "([^\"]+)"$/ do |sample_name,sample_tube_name|
  sample = Sample.find_by_name(sample_name) or raise StandardError, "Could not find a sample named '#{ sample_name }'"
  Factory(:sample_tube, :name => sample_tube_name, :material => sample) or raise StandardError, "Could not create sample tube named '#{ sample_tube_name }'"
end

Then /^the search results I should see are:$/ do |table|
  table.hashes.each do |row|
    Then %Q{I should see "1 #{ row['section'] }"}
    Then %Q{I should see "#{ row['result'] }"}
  end
end
