# frozen_string_literal: true

########################################################################################
# TODO: Remove these from the features and replace them with the new versions
########################################################################################
Then /^the field labeled "([^"]+)" should contain "([^"]*)"$/ do |label, value|
  step "the \"#{label}\" field should contain \"#{value}\""
end

When /^I fill in the field labeled "([^"]+)" with "([^"]*)"$/ do |label, value|
  step("I fill in \"#{label}\" with \"#{value}\"")
end

Then /^the checkbox labeled "([^"]+)" should not be checked$/ do |label|
  step "the \"#{label}\" checkbox should not be checked"
end

Then /^the checkbox labeled "([^"]+)" should be checked$/ do |label|
  step "the \"#{label}\" checkbox should be checked"
end

Then /^the field labeled "([^"]*)" should be disabled$/ do |label|
  find_field(label, disabled: true)
end

Then /^the field labeled "([^"]*)" should not be disabled$/ do |label|
  find_field(label)
end

########################################################################################
# Keep these!
########################################################################################
Then /^I should see the following (required )?fields:$/ do |required, table|
  table.hashes.each do |field|
    if field['type'].include?('/')
      step "I should see the #{required}select field \"#{field['field']}\" with options \"#{field['type']}\""
    else
      step "I should see the #{required}#{field['type']} field \"#{field['field']}\""
    end
  end
end

def assert_label_exists(label_text, required = false)
  selector = "label#{required ? '.required' : ':not(.required)'}"
  assert(
    page.has_css?(selector, visible: :all, text: label_text),
    "The #{label_text.inspect} should #{'not ' unless required}be labeled as 'required' (class=\"required\")"
  )
end

# rubocop:todo Metrics/MethodLength, Metrics/AbcSize
def locate_labeled_field_type(label_text, field_type) # rubocop:todo Metrics/CyclomaticComplexity
  field = page.find_field(label_text) or raise Capybara::ElementNotFound, "Could not find #{label_text.inspect}"
  case field_type
  when 'text'
    field['type'] == 'text' or raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a text field"
  when 'select'
    field.tag_name == 'select' or raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a select field"
  when 'textarea'
    field.tag_name == 'textarea' or
      raise Capybara::ElementNotFound, "Field #{label_text.inspect} is not a textarea field"
  else
    raise StandardError, "Unrecognised field type '#{field_type}'"
  end
  field
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength

Then /^I should see the (required )?(text|select|textarea) field "([^"]+)"$/ do |required, type, field|
  assert_label_exists(field, required)
  locate_labeled_field_type(field, type)
end

# rubocop:todo Layout/LineLength
Then %r{^I should see the (required )?select field "([^"]+)" with options "([^"]+(?:/[^"]+)+)"$} do |required, field, options|
  # rubocop:enable Layout/LineLength
  assert_label_exists(field, required)
  element = locate_labeled_field_type(field, 'select')
  options
    .split('/')
    .each do |option|
      element.all('option').detect { |o| o.text == option } or
        raise Capybara::ElementNotFound, "Field #{field.inspect} has no option #{option.inspect}"
    end
end

Then /^I should see the (required )?select field "([^"]+)" with the option "([^"]+)"$/ do |required, field, option|
  assert_label_exists(field, required)
  element = locate_labeled_field_type(field, 'select')
  element.all('option').detect { |o| o.text == option } or
    raise Capybara::ElementNotFound, "Field #{field.inspect} has no option #{option.inspect}"
end
Then /^I should see the (required )?select field "([^"]+)" without the option "([^"]+)"$/ do |required, field, option|
  assert_label_exists(field, required)
  element = locate_labeled_field_type(field, 'select')
  element.all('option').none? { |o| o.text == option } or
    raise Capybara::ElementNotFound, "Field #{field.inspect} has option #{option.inspect}"
end

Then /^the select field "([^"]+)" should have the option "([^"]+)"$/ do |field, option|
  element = page.find_field(field, visible: :all, disabled: true)
  element.all('option').detect { |o| o.text == option } or
    raise Capybara::ElementNotFound, "Field #{field.inspect} has no option #{option.inspect}"
end

Then /^the select field "([^"]+)" should not have the option "([^"]+)"$/ do |field, option|
  element = page.find_field(field, visible: :all, disabled: true)
  element.all('option').none? { |o| o.text == option } or
    raise Capybara::ElementNotFound, "Field #{field.inspect} has no option #{option.inspect}"
end

Then /^the "([^"]+)" field should be marked in error$/ do |field|
  element = page.find_field(field) or raise Capybara::ElementNotFound, "Field #{field.inspect} not found"
  find(".field_with_errors ##{element['id']}")
end

# There is an issue when attaching a file to a field and using the @javascript tag: the path is relative to some
# location that appears not to be the project root.  So you have to use an absolute path, rather than the relative
# one that is passed.
When /^(?:|I )attach the relative file "([^"]+)" to "([^"]+)"(?: within "([^"]+)")?$/ do |path, field, selector|
  with_scope(selector) { attach_file(field, File.expand_path(path)) }
end

When /^I fill in "([^"]*)" with(?: the)? multiline text:?$/ do |field, value|
  find_field(field).send_keys(value)
rescue NotImplementedError
  fill_in(field, with: value)
end

When /^I fill in the hidden field "([^"]*)" with "([^"]+)"$/ do |field, value|
  find("input##{field}", visible: false).set(value)
end

When /^I accept the action$/ do
  # TODO: Poltergeist doesn't support this
  # sleep(0.3)
  # page.driver.browser.switch_to.alert.accept
end
