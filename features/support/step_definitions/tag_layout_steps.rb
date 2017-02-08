# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

Given /^the ((?:entire plate |inverted )?tag layout template) "([^"]+)" exists$/ do |style, name|
  FactoryGirl.create(style.tr(' ', '_'), name: name)
end

Given /^the tag 2 layout template "([^"]+)" exists$/ do |name|
  FactoryGirl.create(:tag2_layout_template, name: name, oligo: 'AAA')
end

TAG_LAYOUT_TEMPLATE_REGEXP = 'tag layout template "[^\"]+"'
TAG_LAYOUT_REGEXP          = 'tag layout with ID \d+'

Transform /^tag layout template "([^\"]+)"$/ do |name|
  TagLayoutTemplate.find_by(name: name) or raise StandardError, "Cannot find tag layout template #{name}"
end

Transform /^tag layout with ID (\d+)$/ do |id|
  TagLayout.find(id)
end

Given /^the tag group for (tag layout template .+) has (\d+) tags$/ do |template, count|
  (1..count.to_i).each { |index| template.tag_group.tags.create!(map_id: index, oligo: "TAG#{index}") }
end

Given /^the tag group for (#{TAG_LAYOUT_TEMPLATE_REGEXP}|#{TAG_LAYOUT_REGEXP}) is called "([^"]+)"$/ do |target, group_name|
  target.tag_group.update_attributes!(name: group_name)
end

def replace_tag_layout_tags(template, index_to_oligo)
  template.tag_group.tags.destroy_all
  index_to_oligo.each do |tag_attributes|
    template.tag_group.tags.create!(map_id: tag_attributes[:index], oligo: tag_attributes[:oligo])
  end
end

Given /^the tag group for (#{TAG_LAYOUT_TEMPLATE_REGEXP}) contains the following tags:$/ do |template, table|
  replace_tag_layout_tags(template, table.hashes)
end

Given /^the tag group for (#{TAG_LAYOUT_TEMPLATE_REGEXP}) has tags (\d+)\.\.(\d+)$/ do |template, low, high|
  tag_range = Range.new(low.to_i, high.to_i)
  replace_tag_layout_tags(template, tag_range.map { |index| { index: index, oligo: "TAG#{index}" } })
end

# assert simply isn't good enough for displaying the oligos and working out what has gone wrong so this
# method turns a map of well-oligo values to a plate view of how the oligos are laid out.  This can then
# be used for eye checking to see what's going on.
def plate_view_of_oligos(label, mapping)
  plate = []
  mapping.each do |location, oligo|
    location =~ /^([A-H])(\d+)$/ or raise StandardError, "Could not match well location #{location.inspect}"
    row, column = $1.bytes.first - 'A'.bytes.first, $2.to_i - 1
    plate[(row * 12) + column] = oligo
  end

  plate_layout = (1..8).map { |_| [] }
  plate.each_with_index { |oligo, i| plate_layout[i / 12][i % 12] = oligo }

  $stderr.puts "#{label}:"
  plate_layout.map(&:inspect).map(&$stderr.method(:puts))
end

def check_tag_layout(name, well_range, expected_wells_to_oligos)
  plate           = Plate.find_by(name: name) or raise StandardError, "Cannot find plate #{name.inspect}"
  wells_to_oligos = Hash[
    plate.wells.map do |w|
      next unless well_range.include?(w)
      [w.map.description, w.primary_aliquot.try(:tag).try(:oligo) || '']
    end.compact
  ]
  if expected_wells_to_oligos != wells_to_oligos
    plate_view_of_oligos('Expected', expected_wells_to_oligos)
    plate_view_of_oligos('Got',      wells_to_oligos)
    assert(false, 'Tag assignment appears to be invalid')
  end
end

def check_tag2_layout(name, well_range, expected_wells_to_oligos)
  plate           = Plate.find_by(name: name) or raise StandardError, "Cannot find plate #{name.inspect}"
  wells_to_oligos = Hash[
    plate.wells.map do |w|
      next unless well_range.include?(w)
      [w.map.description, w.primary_aliquot.try(:tag2).try(:oligo) || '']
    end.compact
  ]
  if expected_wells_to_oligos != wells_to_oligos
    plate_view_of_oligos('Expected', expected_wells_to_oligos)
    plate_view_of_oligos('Got',      wells_to_oligos)
    assert(false, 'Tag 2 assignment appears to be invalid')
  end
end

Then /^the tag layout on the plate "([^"]+)" should be:$/ do |name, table|
  check_tag_layout(
    name, WellRange.new('A1', 'H12'),
    ('A'..'H').to_a.zip(table.raw).inject({}) do |h, (row_a, row)|
      h.tap { row.each_with_index { |cell, i| h["#{row_a}#{i + 1}"] = cell } }
    end
  )
end

Then /^the tag 2 layout on the plate "([^"]+)" should be:$/ do |name, table|
  check_tag2_layout(
    name, WellRange.new('A1', 'H12'),
    ('A'..'H').to_a.zip(table.raw).inject({}) do |h, (row_a, row)|
      h.tap { row.each_with_index { |cell, i| h["#{row_a}#{i + 1}"] = cell } }
    end
  )
end

Then /^the tags assigned to the plate "([^"]+)" should be:$/ do |name, table|
  check_tag_layout(
    name, WellRange.new('A1', 'H12'),
    Hash[table.hashes.map { |a| [a['well'], a['tag']] }]
  )
end

Then /^the tags assigned to the plate "([^"]+)" should be (\d+)\.\.(\d+) for wells "([^"]+)"$/ do |name, low, high, range|
  tag_range = Range.new(low.to_i, high.to_i)
  raise StandardError, "Tag range #{tag_range.inspect} is not the same size as well range #{range.inspect}" unless tag_range.to_a.size == range.size

  check_tag_layout(
    name, range,
    Hash[range.to_a.zip(tag_range.to_a.map { |v| "TAG#{v}" })]
  )
end

Given /^the UUID for the plate associated with the tag layout with ID (\d+) is "([^"]+)"$/ do |id, uuid_value|
  set_uuid_for(TagLayout.find(id).plate, uuid_value)
end

def pool_by_strategy(source, destination, pooling_strategy)
  Rails.logger.info("Pooling strategy does not fit plate size #{source.size}: #{pooling_strategy.inspect}") unless pooling_strategy.sum == source.size

  source_wells, destination_wells = [], []
  source.wells.walk_in_column_major_order { |well, _| source_wells << well }
  destination.wells.walk_in_column_major_order { |well, _| destination_wells << well }

  pooling_strategy.each_with_index do |pool, submission_id|
    submission_id = Submission.create!(user: User.first || User.create!(login: 'a')).id
    wells_for_source, wells_for_destination = source_wells.slice!(0, pool), destination_wells.slice!(0, pool)
    wells_for_source.zip(wells_for_destination).each do |w|
      RequestType.transfer.create!(asset: w.first, target_asset: w.last, submission_id: submission_id)
      FactoryGirl.create :request_without_submission, asset: w.first, target_asset: w.last, submission_id: submission_id
    end
  end
end

# This fakes out the transfers so that they look like they came from different submissions, effectively meaning
# that the source plate is pooled in columns to the destination plate (it's not actually pooled, it's just the
# indication of what pools will occur).
Given /^the wells for (the plate.+) have been pooled in columns to (the plate.+)$/ do |source, destination|
  pool_by_strategy(source, destination, [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8])
end

Given /^the wells for (the plate.+) have been pooled to (the plate.+) according to the pooling strategy (\d+(?:,\s*\d+)*)$/ do |source, destination, pooling_strategy|
  pool_by_strategy(source, destination, pooling_strategy.split(',').map(&:to_i))
end

Given /^the tag group "(.*?)" exists$/ do |name|
  TagGroup.create!(name: name)
end

Given /^the tag group "(.*?)" has (\d+) tags$/ do |group, count|
  (1..count.to_i).each { |index| TagGroup.find_by!(name: group).tags.create!(map_id: index, oligo: "TAG#{index}") }
end

Given /^well "(.*?)" on the plate "(.*?)" is empty$/ do |well, plate|
  Plate.find_by!(name: plate).wells.located_at(well).first.aliquots.each(&:destroy)
end

Given /^the tag2 layout template "(.*?)" is associated with the last submission$/ do |template|
  Tag2Layout::TemplateSubmission.create!(
    tag2_layout_template: Tag2LayoutTemplate.find_by!(name: template),
    submission: Submission.last
    )
end
