# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

Given /^I have a library tube of stuff called "([^\"]+)"$/ do |name|
  # TODO: check if it should be :library_tube instead
  FactoryGirl.create(:empty_library_tube, name: name)
end

Given /^I have already made a request for library tube "([^\"]+)" within the study "([^\"]+)"$/ do |library_tube_name, study_name|
  library_tube = LibraryTube.find_by(name: library_tube_name) or raise StandardError, "Cannot find library tube #{library_tube_name.inspect}"
  study        = Study.find_by(name: study_name) or raise StandardError, "Cannot find study with name #{study_name.inspect}"
  FactoryGirl.create(:library_creation_request_type).new_request(
    asset: library_tube, study: study,
    request_metadata_attributes: {
      fragment_size_required_from: 111,
      fragment_size_required_to: 222
    }
  ).save!
end

When /^I follow the "([^\"]+)" request$/ do |request_type|
  step(%Q{I follow "#{request_type} request"})
end
