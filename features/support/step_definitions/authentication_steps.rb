# frozen_string_literal: true

Given /^I am using "(.*)" to authenticate$/ do |auth_method|
  configatron.authentication = auth_method
end

Given /^I am logged in as "(.*)"$/ do |login|
  step("I am an \"internal\" user logged in as \"#{login}\"")
end

Given /^I am an? "([^"]*)" user logged in as "([^"]*)"$/ do |role_name, login|
  @current_user =
    FactoryBot.create(
      :user,
      login:,
      first_name: 'John',
      last_name: 'Doe',
      password: 'generic',
      password_confirmation: 'generic',
      email: "#{login}@example.com"
    )

  @current_user.roles << FactoryBot.create(:role, name: role_name)

  visit '/login'
  fill_in('login', with: login)
  fill_in('password', with: 'generic')
  click_button('Login')
end

Given /^there is at least one administrator$/ do
  FactoryBot.create :admin
end

Then /^I should be logged in as "([^"]*)"$/ do |login|
  user = User.find_by(login:)
  assert @current_user == user
end

Given /^user "([^"]*)" has nil first and last names$/ do |login|
  user = User.find_by(login:)
  user.update!(last_name: nil, first_name: nil)
end
