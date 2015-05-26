#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2014 Genome Research Ltd.
Given /^user "([^"]*)" exists$/ do |user_name|
  Factory :user, :login => user_name, :first_name => user_name.titlecase, :last_name => "Smith"
end

Given /^a user with an api key of "([^"]*)" exists$/ do |api_key|
  @current_user = Factory :user, :api_key => api_key
end

Given /^I have an active project called "([^"]*)"$/ do |project_name|
  Factory :project, :name => project_name
end

Then /^the role list table should look like:$/ do |expected_results_table|
  sleep 0.1
  expected_results_table.diff!(table(fetch_table('table#roles_table')))
end

Then /^the user "([^"]*)" roles should look like:$/ do |user, role_table|
  user = User.find_by_login(user) || User.find_by_email(user)
  user_role_table = role_table.class.new([["role"], user.roles.map { |r| r.name}])
  role_table.diff!(user_role_table)
end

Given /^user "([^"]*)" exists with barcode "([^"]*)"$/ do |user_name, barcode|
  Factory :user, :barcode => barcode, :login => user_name
end

Given /^the user with login "([^\"]+)" exists$/ do |login|
  Factory(:user, :login => login)

end


Then /^the user (\d+) should validate the swipecard code "([^\"]+)"/ do |user_id, code|
  user = User.find(user_id)
  assert user.compare_swipecard_code(code)
end
