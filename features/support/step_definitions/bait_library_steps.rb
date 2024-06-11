# frozen_string_literal: true

Then /^there should be no bait library layouts$/ do
  assert_equal(0, BaitLibraryLayout.count, 'There appear to be some bait library layouts')
end

Then 'the bait library for {well_range} of {plate_name} should be {string}' do |range, plate, name|
  bait_library = BaitLibrary.find_by(name:) or raise StandardError, "Cannot find bait library #{name.inspect}"
  bait_libraries = plate.wells.select(&range.method(:include?)).map(&:aliquots).flatten.map(&:bait_library).uniq
  assert_equal([bait_library], bait_libraries, 'The bait libraries do not match what was expected')
end
