# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^the following custom texts are defined$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    ct = FactoryGirl.create(:custom_text, hash)
    ct.save
  end
end

Given /^there is a CustomText with identifier: "([^"]*)", differential: "([^"]*)"$/ do |identifier, differential|
  @current_custom_text = CustomText.find_by(
    identifier: identifier,
    differential: differential
  )

  assert_not_nil @current_custom_text
end

When /^I edit the custom text with identifier "([^"]*)" and differential "([^"]*)"$/ do |identifier, differential|
  step(%Q{I follow "Edit" within "##{identifier}-#{differential}-details"})
end

When /^I delete the custom text with identifier "([^"]*)" and differential "([^"]*)"$/ do |identifier, differential|
  step(%Q{I follow "Delete" within "##{identifier}-#{differential}-details"})
end

When /^I edit the CustomText$/ do
  step(%Q{I follow "Edit" within "##{@current_custom_text.name}-details"})
end

Given /^the application information box should contain "([^\"]*)"$/ do |info_text|
  regexp = Regexp.new(info_text)
  with_scope('#app-info-box') do
    assert page.has_xpath?('//*', text: regexp)
  end
end

Then /^the application information box is not shown$/ do
  assert page.has_no_xpath?('//*[@id="app-info-box"]')
end

Given /^I am viewing the "([^\"]*)" page$/ do |url|
  visit url
end

Then /^I should be at (.+)$/ do |path|
  assert_equal URI.parse(current_url).path, path
end

Given /^I am editing the custom text field "([^\"]+)"$/ do |name|
 field = CustomText.find_by(identifier: name) or raise StandardError, "Cannot find custom text field #{name.inspect}"
 visit edit_admin_custom_text_path(field)
end

Then /^the page should contain the following$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    step "I should see \"#{hash[:text]}\""
  end
end

When /^I fill in the following fields$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    step(%Q{I fill in the field labeled "Custom text #{hash[:label]}" with "#{hash[:value]}"})
  end
end

Then /^I should be able to (enter|edit) the following fields$/ do |action, table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    step(%Q{I fill in "#{hash[:label]}" with "#{hash[:value]}"})
  end

  step 'I press "Save Custom text"'
  case action
  when 'enter'
    step 'I should see "Custom text successfully created"'
  when 'edit'
    step 'I should see "Details have been updated"'
  end
  table.hashes.each do |hash|
    step "I should see \"#{hash[:value]}\""
  end
end
