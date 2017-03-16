# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

Then /^there should be no bait library layouts$/ do
  assert_equal(0, BaitLibraryLayout.count, 'There appear to be some bait library layouts')
end

Then /^the bait library for "([^\"]+)" of (the plate .+) should be "([^\"]+)"$/ do |range, plate, name|
  bait_library   = BaitLibrary.find_by(name: name) or raise StandardError, "Cannot find bait library #{name.inspect}"
  bait_libraries = plate.wells.select(&range.method(:include?)).map(&:aliquots).flatten.map(&:bait_library).uniq
  assert_equal([bait_library], bait_libraries, 'The bait libraries do not match what was expected')
end
