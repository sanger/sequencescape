# frozen_string_literal: true

Given /^I have a library tube of stuff called "([^"]+)"$/ do |name|
  # TODO: check if it should be :library_tube instead
  FactoryBot.create(:empty_library_tube, name: name)
end

Given /^I have already made a request for library tube "([^"]+)" within the study "([^"]+)"$/ do |library_tube_name, study_name|
  library_tube = LibraryTube.find_by(name: library_tube_name) or raise StandardError, "Cannot find library tube #{library_tube_name.inspect}"
  study        = Study.find_by(name: study_name) or raise StandardError, "Cannot find study with name #{study_name.inspect}"
  FactoryBot.create(:library_creation_request_type).create!(
    asset: library_tube, study: study,
    request_metadata_attributes: {
      fragment_size_required_from: 111,
      fragment_size_required_to: 222
    }
  )
end
