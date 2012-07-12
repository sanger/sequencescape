Then /^the bait library index page should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#bait_library_list tr', 'td,th')))
end

Then /^the bait library supplier index should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#bait_library_supplier_list tr', 'td,th')))
end

Then /^the bait library type index should look like:$/ do |expected_results_table|
  expected_results_table.diff!(table(tableish('table#bait_library_types_list tr', 'td,th')))
end

Given /^I have a bait library called "([^"]*)"$/ do |name|
  BaitLibrary.create!(
    :name => name,
    :bait_library_type => BaitLibraryType.find_by_visible(true),
    :bait_library_supplier => BaitLibrary::Supplier.find_by_visible(true),
    :target_species => 'Dragon'
    )
end

Then /^the supplier_identifier for "([^"]*)" should be nil$/ do |name|
  assert BaitLibrary.find_by_name(name).supplier_identifier.nil?
end

Given /^I have a bait library type called "([^"]*)"$/ do |name|
  BaitLibraryType.create!(:name => name)
end

Given /^I have a supplier called "([^"]*)"$/ do |name|
  BaitLibrary::Supplier.create!(:name => name )
end

Then /^the "([^"]*)" called "([^"]*)" should exist$/ do |class_name, name|
  matching = class_name.constantize.find_by_name(name)
  assert matching
end

Given /^the last bait library has type "([^"]*)"$/ do |name|
  BaitLibrary.last.update_attributes(
    :bait_library_type => BaitLibraryType.create!(:name => name)
  )
end

Given /^the last bait library has supplier "([^"]*)"$/ do |name|
  BaitLibrary.last.update_attributes(
    :bait_library_supplier => BaitLibrary::Supplier.create!(:name => name)
  )
end

Given /^the last bait library is hidden$/ do
  BaitLibrary.last.update_attributes(:visible => false)
end

Then /^the submission with UUID "([^"]*)" should not be ready$/ do |uuid|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  assert(!submission.ready?, "Submission is ready (#{submission.state.inspect})")
end

Then /^the submission with UUID "([^\"]*)" should have the error "([^"]*)"$/ do |uuid, error|
  submission = Uuid.with_external_id(uuid).first.try(:resource) or raise StandardError, "Could not find submission with UUID #{uuid.inspect}"
  assert submission.message.include?(error)
end
