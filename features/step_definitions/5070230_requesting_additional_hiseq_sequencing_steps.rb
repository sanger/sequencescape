Given /^I have a library tube of stuff called "([^\"]+)"$/ do |name|
  #todo : check if it should be :library_tube instead
  Factory(:empty_library_tube, :name => name)
end

Given /^I have already made a request for library tube "([^\"]+)" within the study "([^\"]+)"$/ do |library_tube_name,study_name|
  library_tube = LibraryTube.find_by_name(library_tube_name) or raise StandardError, "Cannot find library tube #{ library_tube_name.inspect }"
  study        = Study.find_by_name(study_name) or raise StandardError, "Cannot find study with name #{ study_name.inspect }"
  Factory(:library_creation_request_type).new_request(
    :asset => library_tube, :study => study,
    :request_metadata_attributes => {
      :fragment_size_required_from => 111,
      :fragment_size_required_to   => 222
    }
  ).save!
end

When /^I follow the "([^\"]+)" request$/ do |request_type|
  step(%Q{I follow "#{ request_type } request"})
end
