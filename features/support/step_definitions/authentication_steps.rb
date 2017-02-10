# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

Given /^I am using "(.*)" to authenticate$/ do |auth_method|
  configatron.authentication = auth_method
end

Given /^I am logged in as "(.*)"$/ do |login|
  step(%Q{I am an "internal" user logged in as "#{login}"})
end

Given /^user "(.*)" has a workflow "(.*)"$/ do |login, workflow_name|
  user = @current_user = User.find_by(login: login) or raise StandardError, "Cannot find a user with login '#{login}'"
  workflow = Submission::Workflow.find_by(name: workflow_name) or raise StandardError, "Cannot find the workflow #{workflow_name.inspect}"
  user.workflow_id = workflow.id
  user.save
end

Given /^I am an? "([^\"]*)" user logged in as "([^\"]*)"$/ do |role_name, login|
  wk = Submission::Workflow.find_by!(key: 'short_read_sequencing')

  @current_user = FactoryGirl.create(:user,
    login: login,
    first_name: 'John',
    last_name: 'Doe',
    password: 'generic',
    password_confirmation: 'generic',
    email: "#{login}@example.com",
    workflow_id: wk.id
  )

  @current_user.roles << FactoryGirl.create(:role, name: role_name)

  visit '/login'
  fill_in('login', with: login)
  fill_in('password', with: 'generic')
  click_button('Login')
end

Given /^there is at least one administrator$/ do
  FactoryGirl.create :admin
end

Given /^I am not logged in$/ do
  @current_user = nil
end

Then /^I should not be on the login page$/ do
  # assert_no_tag :tag => :title, :child => "Sequencescape : Login"
  'I should not see "Sequencescape : Login" within "title"'
end

Then /^I should be logged in as "([^\"]*)"$/ do |login|
  user = User.find_by(login: login)
  assert @current_user == user
end

Given /^a user with human barcode "(ID\d+.)" exists$/ do |human_barcode|
  FactoryGirl.create(:user, barcode: human_barcode)
end

Given /^user "([^"]*)" has nil first and last names$/ do |login|
   user = User.find_by(login: login)
   user.update_attributes!(last_name: nil, first_name: nil)
end
