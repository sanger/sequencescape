# frozen_string_literal: true

Given /^I have administrative role$/ do
  @current_user.grant_administrator
end

Given /^I have lab manager role$/ do
  @current_user.grant_lab_manager
end

Given /^the role "([^"]*)" exists$/ do |role_name|
  Role.create!(name: role_name.tr(' ', '_').downcase)
end

Given /^user "([^"]+)" is an administrator$/ do |login|
  user = User.find_by(login:) or raise StandardError, "Cannot find user with login #{login.inspect}"
  user.roles.create!(name: 'administrator')
end
