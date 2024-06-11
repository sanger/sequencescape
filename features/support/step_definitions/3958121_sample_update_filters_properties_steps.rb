# frozen_string_literal: true

Given /^I am the owner of sample "([^"]+)"$/ do |name|
  sample = Sample.find_by!(name:)
  @current_user.grant_owner(sample)
end

Given /^I am an administrator$/ do
  @current_user.roles.create!(name: 'administrator')
  @current_user.reload
end
