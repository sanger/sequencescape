# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^I have the following library tubes with tags( multiplexed in a tube)?:$/ do |create_mx_tube, table|
  number_of_tubes = table.rows.size
  step(%Q{I have a tag group called "My tag group" with #{number_of_tubes} tags})

  mx_tube = FactoryGirl.create(:multiplexed_library_tube) if create_mx_tube
  table.hashes.each do |row|
    barcode, tag_id = ['barcode', 'tag id'].map { |k| row[k] }
    tube = FactoryGirl.create(:full_library_tube, barcode: barcode.to_i)
    tag  = Tag.find_by(map_id: tag_id.match(/(\d+)/)[1].to_i) or raise StandardError, "Cannot find tag #{tag_id.inspect}"
    # tube.aliquots.create!(:tag => tag, :sample => Sample.create!(:name => "sample for tube #{tube.barcode}".gsub(" ","_")))
    tag.tag!(tube)
    RequestType.transfer.create!(asset: tube, target_asset: mx_tube) if mx_tube
  end
end

Then /^the tag changing table should be:$/ do |expected_results_table|
  actual_table = table(fetch_table('table.library_tube_list').collect { |row| row.collect { |cell| cell[/^(Tag [\d]+)|(.+)/] } })
  expected_results_table.diff!(actual_table)
end

Then /^the library tubes should have the following tags:$/ do |table|
  table.hashes.each do |row|
    barcode, tag_id = ['barcode', 'tag id'].map { |k| row[k] }
    assert_equal tag_id.to_i, LibraryTube.find_by(barcode: barcode).primary_aliquot.tag_id
  end
end

When /^I change the tags of the library tubes:$/ do |table|
  library_tubes = []
  tube_to_tags = {}
  table.hashes.each do |row|
    barcode, tag_id = ['barcode', 'tag id'].map { |k| row[k] }
    tube = LibraryTube.find_by(barcode: barcode) or raise StandardError, "Cannot find library tube with barcode #{barcode.inspect}"
    library_tubes << tube

    tag = Tag.find(tag_id)
    tube_to_tags[tube.id] = tag.name
  end

  step 'I am on the tag changing page'
  step(%Q{I fill in "change_tags_library_tube_ids" with "#{library_tubes.map(&:id).join('\n')}"})
  step 'I press "Submit"'
  # assign the correct tag
  tube_to_tags.each do |tube_id, tag_name|
    step %Q{I select "#{tag_name}" from "change_tags_library_tubes[#{tube_id}]"}
  end
  step 'I press "Submit"'
  # done
end

Then /^the last multiplexed library tube should have the following tags:$/ do |tag_table|
  mx_tube = MultiplexedLibraryTube.last

  mx_tube_tag_ids = mx_tube.aliquots.map(&:tag_id)
  expected_tag_ids = tag_table.rows.map { |r| r.first.to_i }
  assert_equal expected_tag_ids.sort, mx_tube_tag_ids.sort
end
