Given /^the following custom texts are defined$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    ct = Factory(:custom_text, hash)
    ct.save
  end
end

Given /^I am viewing the "([^\"]*)" page$/ do |url|
  visit url
end

Then /^I should be at (.+)$/ do |path|
  assert_equal URI.parse(current_url).path, path
end

Given /^I am editing the custom text field "([^\"]+)"$/ do |name|
 field = CustomText.find_by_identifier(name) or raise StandardError, "Cannot find custom text field #{ name.inspect }"
 visit edit_custom_text_path(field)
end

Then /^the page should contain the following$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    Then "I should see \"#{hash[:text]}\""
  end
end

When /^I fill in the following fields$/ do |table|
  # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    When %Q{I fill in the field labeled "Custom text #{ hash[:label] }" with "#{ hash[:value] }"}
  end
end

Then /^I should be able to (enter|edit) the following fields$/ do |action, table|
   # table is a Cucumber::Ast::Table
  table.hashes.each do |hash|
    When %Q{I fill in the field labeled "Custom text #{ hash[:label] }" with "#{ hash[:value] }"}
  end

  And "I press \"Save changes\""
  case action
  when "enter"
    Then "I should see \"Custom text successfully created\""
  when "edit"
    Then "I should see \"Details have been updated\""
  end
  table.hashes.each do |hash|
    Then "I should see \"#{ hash[:value] }\""
  end
end

