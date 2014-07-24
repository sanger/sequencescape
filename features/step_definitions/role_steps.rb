Given /^I have administrative role$/ do
  @current_user.is_administrator
end

Given /^I have lab role$/ do
  @current_user.is_lab
end

Given /^I have lab manager role$/ do
  @current_user.is_lab_manager
end

Given /^the role "([^"]*)" exists$/ do |role_name|
  Role.create!(:name => role_name.gsub(/ /, "_").downcase)
end

Given /^user "([^\"]+)" is an administrator$/ do |login|
  user = User.find_by_login(login) or raise StandardError, "Cannot find user with login #{login.inspect}"
  user.roles.create!(:name => 'administrator')
end

Given /^user "([^\"]+)" is a manager of "([^\"]+)"$/ do |login, name|
  user  = User.find_by_login(login) or raise StandardError, "Cannot find user with login #{login.inspect}"
  study = Study.find_by_name(name) or raise StandardError, "Cannot find study #{name.inspect}"
  user.has_role('manager', study)
end
