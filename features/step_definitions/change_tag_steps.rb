Given /^I have (\d+) library tubes without tag instances$/ do |number_of_tubes|
  tubes = [] 
  1.upto(number_of_tubes.to_i) do |i|
    tubes << Factory(:library_tube, :barcode => i)
  end
  #LibraryTube.import tubes
end

Given /^I have the following library tubes with tags:$/ do |table|
  number_of_tubes = table.rows.size
  Given %Q{I have a tag group called "My tag group" with #{number_of_tubes} tags}
  Given %Q{I have #{number_of_tubes} library tubes without tag instances}

  table.hashes.each do |row|
    barcode, tag_id = ["barcode", "tag id"].map { |k| row[k] }
    tube = LibraryTube.find_by_barcode(barcode)              or raise StandardError, "Cannot find library tube with barcode #{barcode.inspect}"
    tag  = Tag.find_by_map_id(tag_id.match(/(\d+)/)[1].to_i) or raise StandardError, "Cannot find tag #{tag_id.inspect}"
    tube.aliquots.create!(:tag => tag, :sample => Sample.create!(:name => "sample for tube #{tube.barcode}".gsub(" ","_")))
  end
end

Then /^the tag changing table should be:$/ do |expected_results_table|
  actual_table = table( tableish('table.library_tube_list tr', 'td,th').collect{ |row| row.collect{|cell| cell[/^(Tag [\d]+)|(.+)/] }}   )
  expected_results_table.diff!(actual_table)
end

Then /^the library tubes should have the following tags:$/ do |table|
  table.hashes.each do |row|
    barcode, tag_id = ["barcode", "tag id"].map { |k| row[k] }
    assert_equal tag_id.to_i, LibraryTube.find_by_barcode(barcode).primary_aliquot.tag_id
  end
end

When /^I change the tags of the library tubes:$/ do |table|
  library_tubes = []
  tube_to_tags = {}
  table.hashes.each do |row|
    barcode, tag_id = ["barcode", "tag id"].map { |k| row[k] }
    tube = LibraryTube.find_by_barcode(barcode)              or raise StandardError, "Cannot find library tube with barcode #{barcode.inspect}"
    library_tubes << tube

    tag = Tag.find(tag_id)
    tube_to_tags[tube.id] = tag.name
  end

  Given "I am on the tag changing page"
  Given %Q{I fill in "change_tags_library_tube_ids" with "#{library_tubes.map(&:id).join('\n')}"}
  Then %Q{I press "Submit"}
  # assign the correct tag
  tube_to_tags.each do|tube_id, tag_name| 
    Then %Q{I select "#{tag_name}" from "change_tags_library_tubes[#{tube_id}]"}
  end
  Then %Q{I press "Submit"}
  #done
end
