
Given /^a state "([^"]*)" to lane named "([^"]*)"$/ do |status, name|
  FactoryBot.create(:lane, name: name, qc_state: status)
end

Given /^an unreleasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by(name: name)
  lane.external_release = false
  lane.save
end

Given /^an releasable lane named "([^"]*)"$/ do |name|
  lane = Lane.find_by(name: name)
  lane.external_release = true
  lane.save
end
