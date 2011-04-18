Given /^a state "([^"]*)" to lane named "([^"]*)"$/ do |status,name|
  Factory(:lane, :name => name, :qc_state => status)
end

Given /^an unreleasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by_name(name)
  lane.external_release = false
  lane.save
end

Given /^an releasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by_name(name)
  lane.external_release = true
  lane.save
end
