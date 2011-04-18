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
  expected_results_table.diff!(table(tableish('table#roles_table tr', 'td,th')))
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
