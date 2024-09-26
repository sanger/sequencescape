# frozen_string_literal: true

Given /^a "([^"]*)" tube called "([^"]*)" exists$/ do |tube_purpose, tube_name|
  purpose = Tube::Purpose.find_by!(name: tube_purpose)
  test = purpose.target_type.constantize.create!(name: tube_name, purpose: purpose)
end
