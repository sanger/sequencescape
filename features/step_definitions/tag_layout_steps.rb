Given /^the tag layout template "([^"]+)" exists$/ do |name|
  Factory(:tag_layout_template, :name => name)
end

TAG_LAYOUT_TEMPLATE_REGEXP = 'tag layout template "[^\"]+"'
TAG_LAYOUT_REGEXP          = 'tag layout with ID \d+'

Transform /^tag layout template "([^\"]+)"$/ do |name|
  TagLayoutTemplate.find_by_name(name) or raise StandardError, "Cannot find tag layout template #{name}"
end

Transform /^tag layout with ID (\d+)$/ do |id|
  TagLayout.find(id)
end

Given /^the tag group for (#{TAG_LAYOUT_TEMPLATE_REGEXP}|#{TAG_LAYOUT_REGEXP}) is called "([^"]+)"$/ do |target, group_name|
  target.tag_group.update_attributes!(:name => group_name)
end

Given /^the tag group for (#{TAG_LAYOUT_TEMPLATE_REGEXP}) contains the following tags:$/ do |template, table|
  template.tag_group.tags.destroy_all
  table.hashes.each do |tag_attributes|
    template.tag_group.tags.create!(:map_id => tag_attributes[:index], :oligo => tag_attributes[:oligo])
  end
end

# assert simply isn't good enough for displaying the oligos and working out what has gone wrong so this
# method turns a map of well-oligo values to a plate view of how the oligos are laid out.  This can then
# be used for eye checking to see what's going on.
def plate_view_of_oligos(label, mapping)
  plate = []
  mapping.each do |location, oligo|
    location =~ /^([A-H])(\d+)$/ or raise StandardError, "Could not match well location #{location.inspect}"
    row, column = $1.bytes.first-'A'.bytes.first, $2.to_i-1
    plate[(row*12)+column] = oligo
  end

  plate_layout = (1..8).map { |_| [] }
  plate.each_with_index { |oligo, i| plate_layout[i/12][i%12] = oligo }

  $stderr.puts "#{label}:"
  plate_layout.map(&:inspect).map(&$stderr.method(:puts))
end

Then /^the tags assigned to the plate "([^"]+)" should be:$/ do |name, table|
  plate                    = Plate.find_by_name(name) or raise StandardError, "Cannot find plate #{name.inspect}"
  expected_wells_to_oligos = Hash[table.hashes.map { |a| [ a['well'], a['tag'] ] }]
  wells_to_oligos          = Hash[plate.wells.map { |w| [ w.map.description, w.primary_aliquot.tag.try(:oligo) ] }]
  if expected_wells_to_oligos != wells_to_oligos
    plate_view_of_oligos('Expected', expected_wells_to_oligos)
    plate_view_of_oligos('Got',      wells_to_oligos)
    assert(false, 'Tag assignment appears to be invalid')
  end
end

Given /^the UUID for the plate associated with the tag layout with ID (\d+) is "([^"]+)"$/ do |id, uuid_value|
  set_uuid_for(TagLayout.find(id).plate, uuid_value)
end

# This fakes out the transfers so that they look like they came from different submissions, effectively meaning
# that the source plate is pooled in columns to the destination plate (it's not actually pooled, it's just the
# indication of what pools will occur).
Given /^the wells for (the plate.+) have been pooled in columns to (the plate.+)$/ do |source, destination|
  # Pair up the wells and then pool them in columns
  paired_wells, pooled = source.wells.zip(destination.wells), (1..12).map { |_| [] }
  paired_wells.each_with_index { |pair, index| pooled[index%12] << pair }

  # Each pool has a unique submission ID that we'll consider to be their index!
  pooled.each_with_index do |pool, submission_id|
    pool.each { |left, right| TransferRequest.create!(:asset => left, :target_asset => right, :submission_id => submission_id) }
  end
end
