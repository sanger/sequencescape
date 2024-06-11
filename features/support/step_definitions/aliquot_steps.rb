# frozen_string_literal: true

# Comparing aliquots is about comparing their sample & tag, not their ID nor the receptacle they are in.
def assert_equal_aliquots(expected, received)
  expected_details = expected.map { |aliquot| [aliquot.sample_id, aliquot.tag_id] }.sort
  received_details = received.map { |aliquot| [aliquot.sample_id, aliquot.tag_id] }.sort
  assert_equal expected_details, received_details, 'Aliqouts are not as expected'
end

Then 'the aliquots of {uuid} should be the same as the wells {well_range} of {plate_name}' do |receptacle, range, plate|
  assert_equal_aliquots(plate.wells.select(&range.method(:include?)).map(&:aliquots).flatten, receptacle.aliquots)
end

Given /^the sample tube "([^"]+)" has (\d+) aliquots$/ do |tube_name, number|
  tube = SampleTube.find_by(name: tube_name) or raise "Can't find SampleTube named #{tube_name}"
  1
    .upto(number.to_i - tube.aliquots.size)
    .each do |_i|
      tube.receptacle.aliquots << FactoryBot.create(:aliquot, tag: FactoryBot.create(:tag), receptacle: tube)
    end
end

Given /^the aliquots in the library tube called "([^"]+)" have been modified$/ do |name|
  tube = LibraryTube.find_by(name:) or raise "Can't find library tube named #{name.inspect}"
  tube.aliquots.each do |a|
    a.updated_at = Time.zone.now
    a.save(validate: false)
  end
end
