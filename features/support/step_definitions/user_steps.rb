# frozen_string_literal: true

Given /^user "([^"]*)" exists$/ do |user_name|
  FactoryBot.create :user, login: user_name, first_name: user_name.titlecase, last_name: 'Smith'
end

Given /^a user with an api key of "([^"]*)" exists$/ do |api_key|
  @current_user = FactoryBot.create :user, api_key:
end

Given /^I have an active project called "([^"]*)"$/ do |project_name|
  FactoryBot.create :project, name: project_name
end

Then /^the role list table should look like:$/ do |expected_results_table|
  sleep 0.1
  expected_results_table.diff!(table(fetch_table('table#roles_table')))
end

Then /^the user "([^"]*)" should have just the role "([^"]*)"$/ do |user, role|
  user = User.find_by!(email: user)
  assert_equal user.roles.pluck(:name), [role]
end

Given /^user "([^"]*)" exists with barcode "([^"]*)"$/ do |user_name, barcode|
  if User.find_by(login: user_name)
    User.find_by(login: user_name).update!(barcode:)
  else
    FactoryBot.create :user, barcode: barcode, login: user_name
  end
end

Given /^the user with login "([^"]+)" exists$/ do |login|
  User.find_by(login:) || FactoryBot.create(:user, login:)
end

Then /^the user (\d+) should validate the swipecard code "([^"]+)"/ do |user_id, code|
  user = User.find(user_id)
  assert user.compare_swipecard_code(code)
end
