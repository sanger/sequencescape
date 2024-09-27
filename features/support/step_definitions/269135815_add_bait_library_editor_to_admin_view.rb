# frozen_string_literal: true

Then /^the bait library index page should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#bait_library_list')))
end

Then /^the bait library supplier index should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#bait_library_supplier_list')))
end

Then /^the bait library type index should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#bait_library_types_list')))
end

Given /^I have a bait library called "([^"]*)"$/ do |name|
  BaitLibrary.create!(
    name: name,
    bait_library_type: BaitLibraryType.find_by(visible: true),
    bait_library_supplier: BaitLibrary::Supplier.find_by(visible: true),
    target_species: 'Dragon'
  )
end

Then /^the supplier_identifier for "([^"]*)" should be nil$/ do |name|
  assert BaitLibrary.find_by(name:).supplier_identifier.nil?
end

Given /^I have a bait library type called "([^"]*)"$/ do |name|
  BaitLibraryType.create!(name: name, category: 'standard')
end

Given /^I have a supplier called "([^"]*)"$/ do |name|
  BaitLibrary::Supplier.create!(name:)
end

Then /^the "([^"]*)" called "([^"]*)" should exist$/ do |class_name, name|
  matching = class_name.constantize.find_by(name:)
  assert matching
end

Given /^the last bait library has type "([^"]*)"$/ do |name|
  BaitLibrary.last.update(bait_library_type: BaitLibraryType.create!(name: name, category: 'standard'))
end

Given /^the last bait library has supplier "([^"]*)"$/ do |name|
  BaitLibrary.last.update(bait_library_supplier: BaitLibrary::Supplier.create!(name:))
end

Given /^the last bait library is hidden$/ do
  BaitLibrary.last.update(visible: false)
end
