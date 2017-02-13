# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^an library tube named "([^"]*)"$/ do |name|
  librarytube = FactoryGirl.create(:empty_library_tube, name: name)
end

Given /^library tube "([^"]*)" is bounded to the study "([^"]*)"$/ do |library_name, study_name|
  study = Study.find_by(name: study_name)
  librarytube = LibraryTube.find_by(name: library_name)
  librarytube.studies << study
end
