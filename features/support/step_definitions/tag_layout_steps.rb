# frozen_string_literal: true

Given /^the ((?:entire plate |inverted )?tag layout template) "([^"]+)" exists$/ do |style, name|
  FactoryBot.create(style.tr(' ', '_'), name: name)
end

Given /^the tag 2 layout template "([^"]+)" exists$/ do |name|
  FactoryBot.create(:tag2_layout_template, name: name, oligo: 'AAA')
end

TAG_LAYOUT_TEMPLATE_REGEXP = 'tag layout template "[^\"]+"'
TAG_LAYOUT_REGEXP = 'tag layout with ID \d+'

Given 'the tag group for {tag_layout_template} has {int} tags' do |template, count|
  (1..count).each { |index| template.tag_group.tags.create!(map_id: index, oligo: "TAG#{index}") }
end

Given 'the tag group for {tag_layout_template} is called {string}' do |target, group_name|
  target.tag_group.update!(name: group_name)
end

Given 'the tag group for {tag_layout} is called {string}' do |target, group_name|
  target.tag_group.update!(name: group_name)
end

def replace_tag_layout_tags(template, index_to_oligo)
  template.tag_group.tags.destroy_all
  index_to_oligo.each do |tag_attributes|
    template.tag_group.tags.create!(map_id: tag_attributes[:index], oligo: tag_attributes[:oligo])
  end
end

Given /^the tag group for (tag layout template "([^"]+)") contains the following tags:$/ do |template, table|
  replace_tag_layout_tags(template, table.hashes)
end

# assert simply isn't good enough for displaying the oligos and working out what has gone wrong so this
# method turns a map of well-oligo values to a plate view of how the oligos are laid out.  This can then
# be used for eye checking to see what's going on.
def plate_view_of_oligos(label, mapping) # rubocop:todo Metrics/AbcSize
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

def check_tag_layout(name, well_range, expected_wells_to_oligos) # rubocop:todo Metrics/MethodLength
  plate = Plate.find_by(name: name) or raise StandardError, "Cannot find plate #{name.inspect}"

  wells_to_oligos =
    plate
      .wells
      .filter_map do |w|
        next unless well_range.include?(w)
        [w.map.description, w.primary_aliquot.try(:tag).try(:oligo) || '']
      end
      .to_h
  if expected_wells_to_oligos != wells_to_oligos
    plate_view_of_oligos('Expected', expected_wells_to_oligos)
    plate_view_of_oligos('Got', wells_to_oligos)
    assert(false, 'Tag assignment appears to be invalid')
  end
end
def check_tag2_layout(name, well_range, expected_wells_to_oligos) # rubocop:todo Metrics/MethodLength
  plate = Plate.find_by(name: name) or raise StandardError, "Cannot find plate #{name.inspect}"
  wells_to_oligos =
    plate
      .wells
      .filter_map do |w|
        next unless well_range.include?(w)

        [w.map.description, w.primary_aliquot.try(:tag2).try(:oligo) || '']
      end
      .to_h
  if expected_wells_to_oligos != wells_to_oligos
    plate_view_of_oligos('Expected', expected_wells_to_oligos)
    plate_view_of_oligos('Got', wells_to_oligos)
    assert(false, 'Tag 2 assignment appears to be invalid')
  end
end
Then /^the tag layout on the plate "([^"]+)" should be:$/ do |name, table|
  check_tag_layout(
    name,
    WellRange.new('A1', 'H12'),
    ('A'..'H')
      .to_a
      .zip(table.raw)
      .inject({}) { |h, (row_a, row)| h.tap { row.each_with_index { |cell, i| h["#{row_a}#{i + 1}"] = cell } } }
  )
end

Then /^the tag 2 layout on the plate "([^"]+)" should be:$/ do |name, table|
  check_tag2_layout(
    name,
    WellRange.new('A1', 'H12'),
    ('A'..'H')
      .to_a
      .zip(table.raw)
      .inject({}) { |h, (row_a, row)| h.tap { row.each_with_index { |cell, i| h["#{row_a}#{i + 1}"] = cell } } }
  )
end

Given /^the UUID for the plate associated with the tag layout with ID (\d+) is "([^"]+)"$/ do |id, uuid_value|
  set_uuid_for(TagLayout.find(id).plate, uuid_value)
end

# Pooling from source plate ("Testing the API") to destination plate ("Testing the tagging") with a specified pooling
# strategy
#
# rubocop:todo Metrics/MethodLength
def pool_by_strategy(source, destination, pooling_strategy) # rubocop:todo Metrics/AbcSize
  unless pooling_strategy.sum == source.size
    Rails.logger.info("Pooling strategy does not fit plate size #{source.size}: #{pooling_strategy.inspect}")
  end

  # Column major: reads columns from left to right, top to bottom
  # Row major: reads rows from top to bottom, left to right
  # For example, a 96-well plate would be read as: A1, B1, C1, D1, E1, F1, G1, H1, A2, B2, C2, D2, E2, F2, G2, H2, ...
  source_wells = source.wells.in_column_major_order.to_a
  destination_wells = destination.wells.in_column_major_order.to_a

  pooling_strategy.each_with_index do |pool, _old_submission_id|
    # This will generate a new submission for each pool. So the number of submissions will be equal to the number of
    # pools. For example, for a pooling strategy of [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8], there will be 12 submissions.
    submission = Submission.create!(user: User.first || User.create!(login: 'a'))
    submission_id = submission.id
    # Slice operation cuts the array in place (i.e., removes the elements cut from the well array),
    # so we need to assign the result to a new variable
    wells_for_source, wells_for_destination = source_wells.slice!(0, pool), destination_wells.slice!(0, pool)
    wells_for_source
      .zip(wells_for_destination)
      .each do |w|
        # Because of the way we use zip w.first would be the source, w.last would be the destination
        # This is the transfer request that would be created by the API.
        # Note that transfer request behavior not used for input plates. For input plates, it is overridden
        # to use requests (see app/models/well.rb:120).
        # Creating TransferRequests invokes a callback that transfers aliquots from source to destination wells.
        TransferRequest.create!(asset: w.first, target_asset: w.last, submission_id: submission_id)
        # This request is for the source plate.
        FactoryBot.create :request_without_submission,
                          asset: w.first,
                          target_asset: w.last,
                          submission_id: submission_id
      end
  end

  # Create a request for each well in the destination plate
  # This is required for input plates
  if destination.purpose.is_a?(PlatePurpose::Input)
    destination.wells.each do |well|
      FactoryBot.create(:customer_request, asset: well, sti_type: 'Request::LibraryCreation', state: 'pending')
    end
  end
end
# rubocop:enable Metrics/MethodLength
# This fakes out the transfers so that they look like they came from different submissions, effectively meaning
# that the source plate is pooled in columns to the destination plate (it's not actually pooled, it's just the
# indication of what pools will occur).
Given 'the wells for {plate_name} have been pooled in columns to {plate_name}' do |source, destination|
  pool_by_strategy(source, destination, [8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8, 8])
end

# rubocop:todo Layout/LineLength
Given 'the wells for {plate_name} have been pooled to {plate_name} according to the pooling strategy {integer_array}' do |source, destination, pooling_strategy|
  # rubocop:enable Layout/LineLength
  pool_by_strategy(source, destination, pooling_strategy)
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
