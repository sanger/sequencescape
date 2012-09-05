Given /^an library tube named "([^"]*)"$/ do |name|
  librarytube = Factory(:empty_library_tube, :name => name)
end

Given /^library tube "([^"]*)" is bounded to the study "([^"]*)"$/ do |library_name,study_name|
  study = Study.find_by_name(study_name)
  librarytube = LibraryTube.find_by_name(library_name)
  librarytube.studies << study
end
