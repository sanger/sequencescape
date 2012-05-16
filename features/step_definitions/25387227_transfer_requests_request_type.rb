Then /^the request type of transfer requests (to|from) "([^\"]+)" on (the plate .+) should be "([^\"]+)"$/ do |direction, range, plate, type|
  plate.wells.select(&range.method(:include?)).each do |well|
    assert_request_state(type, well, direction, TransferRequest)
  end
end

Then /^the request type of all the transfer requests (to|from) the (the multiplexed library tube .+) should be "([^"]*)"$/ do |direction, target, type|
  assert_request_type(type, target, direction, TransferRequest)
end

Then /^the request type of all the transfer requests (to|from) the (the plate .+) should be "([^"]*)"$/ do |direction, target, type|
  assert_request_type(type, target.wells, direction, TransferRequest)
end

def assert_request_type(type, targets, direction, request_class)
  association = (direction == 'to') ? :requests_as_target : :requests_as_source
  assert_equal(
    [ RequestType.find_by_name(type).id ],
    Array(targets).map(&association).flatten.select { |r| r.is_a?(request_class) }.map(&:request_type_id).uniq,
    "Some #{request_class.name} requests have the wrong request type"
  )
end
