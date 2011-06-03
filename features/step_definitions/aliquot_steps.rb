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
