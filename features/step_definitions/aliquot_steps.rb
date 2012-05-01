# Comparing aliquots is about comparing their sample & tag, not their ID nor the receptacle they are in.
def assert_equal_aliquots(expected, received)
  expected_details = expected.map { |aliquot| [ aliquot.sample_id, aliquot.tag_id ] }.sort
  received_details = received.map { |aliquot| [ aliquot.sample_id, aliquot.tag_id ] }.sort
  assert_equal expected_details, received_details, 'Aliqouts are not as expected'
end

Then /^the aliquots of (the .+) should be the same as the wells "([^\"]+)" of (the plate .+)$/ do |receptacle, range, plate|
  assert_equal_aliquots(
    plate.wells.select(&range.method(:include?)).map(&:aliquots).flatten,
    receptacle.aliquots
  )
end

Then /^the aliquot (\d+) should belong to the study named "([^\"]*)"$/ do |aliquot_id, study_name|
  aliquot = Aliquot.find(aliquot_id) or raise StandardError, "Cannot find aliquot #{aliquot_id}"
  study  = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  assert_equal study, aliquot.study
end

Then /^all aliquots in asset (\d+) should belong to the study named "([^\"]*)"$/ do |asset_id, study_name|
  asset = Asset.find(asset_id) or raise StandardError, "Cannot find Asset #{asset_id}"
  study  = Study.find_by_name(study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  asset.aliquots.each { |a| assert_equal study, a.study }
end

Given /^the sample tube "([^\"]+)" has (\d+) aliquots$/ do |tube_name, number|
  tube = SampleTube.find_by_name(tube_name) or raise "Can't find SampleTube named #{tube_name}"
  1.upto(number.to_i-tube.aliquots.size).each do |i|
    tube.aliquots.create!(:sample => Factory(:sample, :name => "sample_#{i}_for_tube_#{tube_name}"), :tag => Factory(:tag))
  end
end

Given /^the aliquots in the library tube called "([^\"]+)" have been modified$/ do |name|
  tube = LibraryTube.find_by_name(name) or raise "Can't find library tube named #{name.inspect}"
  tube.aliquots.each { |a| a.updated_at = Time.now ; a.save(false) }
end
