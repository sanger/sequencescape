# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Then /^the request class of all the transfer requests (to|from) the (the multiplexed library tube .+) should be "([^"]*)"$/ do |direction, target, type|
  assert_request_class(type, target, direction, TransferRequest)
end

Then /^the request class of all the transfer requests (to|from) the (the plate .+) should be "([^"]*)"$/ do |direction, target, type|
  assert_request_class(type, target.wells, direction, TransferRequest)
end

def assert_request_class(type, targets, direction, request_class)
  association = (direction == 'to') ? :target_asset_id : :asset_id
  assert_equal(
    ["TransferRequest::#{type.classify}"],
    TransferRequest.where(association => targets).pluck(:sti_type).uniq,
    "Some #{request_class.name} requests have the wrong class"
  )
end
