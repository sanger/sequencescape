Given /^I have (\d+) library tubes without tag instances$/ do |number_of_tubes|
  tubes = [] 
  1.upto(number_of_tubes.to_i) do |i|
    tubes << LibraryTube.new(:barcode => i)
  end
  LibraryTube.import tubes
end

Given /^I have the following library tubes with tags:$/ do |table|
  number_of_tubes = table.rows.size
  Given %Q{I have a tag group called "My tag group" with #{number_of_tubes} tags}
  Given %Q{I have #{number_of_tubes} library tubes without tag instances}

  table.rows.each do |barcode, tag_id|
    tube = LibraryTube.find_by_barcode(barcode)              or raise StandardError, "Cannot find library tube with barcode #{barcode.inspect}"
    tag  = Tag.find_by_map_id(tag_id.match(/(\d+)/)[1].to_i) or raise StandardError, "Cannot find tag #{tag_id.inspect}"
    tag.tag!(tube)
  end
end

Then /^the tag changing table should be:$/ do |expected_results_table|
  actual_table = table( tableish('table.library_tube_list tr', 'td,th').collect{ |row| row.collect{|cell| cell[/^(Tag [\d]+)|(.+)/] }}   )
  expected_results_table.diff!(actual_table)
end

Then /^the library tubes should have the following tags:$/ do |table|
  table.rows.each do |library_tube, tag|
    tag_found = LibraryTube.find_by_barcode(library_tube).tag
    expected_tag = tag.match(/(\d+)/)[1].to_i
    assert tag_found, expected_tag
  end
end
