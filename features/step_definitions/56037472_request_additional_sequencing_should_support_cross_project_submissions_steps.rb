Given /^I have a multiplexed library tube called "(.*?)"$/ do |name|
  Purpose.find_by_name('Standard MX').create!(:name=>name,:qc_state=>'pending')
end

Then /^the "(.*?)" requests on "(.*?)" should have no study or project$/ do |request_type, asset_name|
  Asset.find_by_name(asset_name).requests.each do |request|
    next unless request.request_type.name == request_type
    assert request.initial_project_id.nil?
    assert request.initial_study_id.nil?
  end
end

Then /^the multiplexed library tube "(.*?)" contains "(.*?)"$/ do |tube_name, library_tube_name|
  library_tube = LibraryTube.find_by_name(library_tube_name)
  library_tube.aliquots.each do |aliquot|
    new_aliquot = aliquot.clone
    new_aliquot.library = library_tube
    MultiplexedLibraryTube.find_by_name(tube_name).aliquots << new_aliquot
    new_aliquot.save!
    AssetLink.create!(:ancestor=>library_tube, :descendant=> MultiplexedLibraryTube.find_by_name(tube_name), :direct=>true)
  end
end

Given /^the library tube "(.*?)" has aliquots with tag (\d+) under project "(.*?)"$/ do |library_tube_name, tag_id, project_name|
  LibraryTube.find_by_name(library_tube_name).aliquots.each do |aliquot|
    aliquot.update_attributes!(:project=>Project.find_by_name(project_name))
    aliquot.update_attributes!(:tag_id=>tag_id)
  end
end

Then /^the multiplexed library tube "(.*?)" should have (\d+) "(.*?)" requests$/ do |mx_library_tube_name, count, request_type|
  assert_equal count.to_i, MultiplexedLibraryTube.find_by_name(mx_library_tube_name).requests.select {|r| r.request_type.name == request_type}.count
end
Then /^the last submission should be called "(.*?)"$/ do |name|
  assert_equal name, Submission.last.name
end
