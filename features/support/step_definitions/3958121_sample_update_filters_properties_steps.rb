
Given /^I am the owner of sample "([^\"]+)"$/ do |name|
  sample = Sample.find_by!(name: name)
  @current_user.is_owner_of(sample)
end

Given /^I am an administrator$/ do
  @current_user.roles.create!(name: 'administrator')
  @current_user.reload
end

# TODO[xxx]: table cells don't appear to play nicely!
Then /^I should see "([^\"]+)" set to "([^\"]+)"$/ do |property_name, value|
  step %Q{I should see "#{property_name}"}
  step %Q{I should see "#{value}"}
end
