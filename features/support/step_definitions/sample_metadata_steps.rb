Given /^the fields of the sample_metadata for the sample called "([^"]+)" are prepopulated$/ do |name|
  sample = Sample.find_by!(name: name)
  sample.update_attributes!(sample_metadata_attributes: FactoryBot.attributes_for(:sample_metadata_for_api))
end
