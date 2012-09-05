########################################################################################
# TODO: Remove these from the features and replace them with the new versions
########################################################################################
Then /^the field labeled "([^"]+)" should contain "([^"]*)"$/ do |label, value|
  Then %Q{the "#{ label }" field should contain "#{ value }"}
end

When /^I fill in the field labeled "([^"]+)" with "([^"]*)"$/ do |label, value|
  When %Q{I fill in "#{ label }" with "#{ value }"}
end

Then /^the checkbox labeled "([^"]+)" should not be checked$/ do |label|
  Then %Q{the "#{ label }" checkbox should not be checked}
end

Then /^the checkbox labeled "([^"]+)" should be checked$/ do |label|
  Then %Q{the "#{ label }" checkbox should be checked}
end

Then /^option "([^"]*)" in the menu labeled "([^"]*)" should be selected$/ do |arg1, arg2|
  pending # express the regexp above with the code you wish you had
end

When /^I press exactly "([^\"]*)"$/ do |button|
  begin
    click_button(/\A#{button}\z/)
  rescue
    save_and_open_page
    raise
  end
end

Then /^the field "([^"]*)" should be empty$/ do |field|
  field_value = field_labeled(field).value
  assert(field_value.blank?, "Field #{ field.inspect } is not blank")
end

########################################################################################
# Keep these!
########################################################################################
Then /^I should see the following (required )?fields:$/ do |required,table|
  table.hashes.each do |field|
    if field['type'].include?('/')
      Then %Q{I should see the #{ required }select field "#{ field['field'] }" with options "#{ field['type'] }"}
    else
      Then %Q{I should see the #{ required }#{ field['type'] } field "#{ field['field'] }"}
    end
  end
end

def assert_label_exists(label_text, required = false)
  selector = 'label' << (required ? '.required' : ':not(.required)')
  assert(page.has_css?(selector), "The #{ label_text.inspect } should #{ required ? '' : 'not '}be labeled as 'required' (class=\"required\")")
end

def locate_labeled_field_type(label_text, field_type)
  field = page.find_field(label_text) or raise Capybara::ElementNotFound, "Could not find #{ label_text.inspect }"
  case field_type
  when 'text'     then field.node.xpath("self::input[@type='text']") or raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a text field"
  when 'select'   then field.node.xpath("self::select")              or raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a select field"
  when 'textarea' then field.node.xpath("self::textarea")            or raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a textarea field"
  else raise StandardError, "Unrecognised field type '#{ field_type }'"
  end
  return field
end

Then /^I should see the (required )?(text|select|textarea) field "([^\"]+)"$/ do |required, type, field|
  assert_label_exists(field, required)
  locate_labeled_field_type(field, type)
end

Then /^I should not see the (text|select|textarea) field "([^\"]+)"$/ do |type, field|
  begin
    locate_labeled_field_type(field, type)
    assert(false, "The field #{ field.inspect } exists!")
  rescue Capybara::ElementNotFound => exception
    # This is fine!
  end
end

Then /^I should see the (required )?select field "([^\"]+)" with options "([^\"]+(?:\/[^\"]+)+)"$/ do |required, field, options|
  assert_label_exists(field, required)
  element = locate_labeled_field_type(field, 'select')
  options.split('/').each do |option|
    element.node.xpath("option[text()='#{option}']") or raise Capybara::ElementNotFound, "Field #{field.inspect} has no option #{option.inspect}"
  end
end

Then /^the "([^\"]+)" field should be marked in error$/ do |field|
  element = page.find_field(field) or raise Capybara::ElementNotFound, "Field #{ field.inspect } not found"
  assert(element.node.xpath("self::*[contains(@class, 'fieldWithErrors')]"), "Field #{field.inspect} does not appear to be marked in error")
end

# There is an issue when attaching a file to a field and using the @javascript tag: the path is relative to some
# location that appears not to be the project root.  So you have to use an absolute path, rather than the relative
# one that is passed.
When /^(?:|I )attach the relative file "([^\"]+)" to "([^\"]+)"(?: within "([^\"]+)")?$/ do |path, field, selector|
  with_scope(selector) do
    attach_file(field, File.expand_path(path))
  end
end

When /^I fill in "([^"]*)" with(?: the)? multiline text:?$/ do |field, value|
  fill_in(field, :with => value)
end

Then /^"([^\"]+)" should be selected from "([^\"]+)"$/ do |value, name|
  assert_equal([ value ], find_field(name).value, "Field #{name.inspect} does not have the correct value selected")
end

Then /^I expect an exception to be raised when I press "([^"]*)"(?: within "([^"]*)")?$/ do |button, selector|
  begin
    with_scope(selector) do
      click_button(button)
    end
    fail("No exception raised!")
  rescue RuntimeError => exception  # 'fail' raises, so we need to check that
    raise
  rescue => exception
    # Good, that was expected
  end
end

When /^I accept the action$/ do
  page.driver.browser.switch_to.alert.accept
end
