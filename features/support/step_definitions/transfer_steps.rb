# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015 Genome Research Ltd.

TRANSFER_TYPES = [
  'between plates',
  'from plate to tube'
]

TRANSFER_TYPES_REGEXP = TRANSFER_TYPES.join('|')

def transfer_model(name)
  "transfer/#{name}".gsub(/\s+/, '_').camelize.constantize
end

Given /^the UUID for the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |model, id, uuid_value|
  set_uuid_for(transfer_model(model).find(id), uuid_value)
end

Given /^the transfer (between plates|from plate to tube) exists with ID (\d+)$/ do |name, id|
  FactoryGirl.create(:"transfer_#{name.gsub(/\s+/, '_')}", id: id)
end

Given /^the UUID for the (source|destination) of the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |target, model, id, uuid_value|
  set_uuid_for(transfer_model(model).find(id).send(target), uuid_value)
end

Given /^the ((?:pooling ||multiplex )?transfer template) called "([^\"]+)" exists$/ do |type, name|
  FactoryGirl.create(type.gsub(/\s/, '_').to_sym, name: name)
end

Then /^the transfers from (the plate .+) to (the plate .+) should be:$/ do |source, destination, table|
  table.hashes.each do |transfers|
    source_well_location, destination_well_location = transfers['source'], transfers['destination']

    source_well      = source.wells.located_at(source_well_location).first           or raise StandardError, "Plate #{source.id} does not have well #{source_well_location.inspect}"
    destination_well = destination.wells.located_at(destination_well_location).first or raise StandardError, "Plate #{destination.id} does not have well #{destination_well_location.inspect}"
    assert_not_nil(TransferRequest.between(source_well, destination_well).first, "No transfer between #{source_well_location.inspect} and #{destination_well_location.inspect}")
  end
end

Given /^a transfer plate exists with ID (\d+)$/ do |id|
  FactoryGirl.create(:transfer_plate, id: id)
end

Given /^a (source|destination) transfer plate called "([^\"]+)" exists$/ do |type, name|
  FactoryGirl.create("#{type}_transfer_plate", name: name)
end

Given /^the plate "(.*?)" has additional wells$/ do |name|
  Plate.find_by(name: name).tap do |plate|
    plate.wells << ['C1', 'D1'].map do |location|
      map = Map.where_description(location).where_plate_size(plate.size).where_plate_shape(AssetShape.find_by(name: 'Standard')).first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
      FactoryGirl.create(:tagged_well, map: map)
    end
  end
end

Given /^a destination transfer plate called "([^\"]+)" exists as a child of "([^\"]+)"$/ do |name, parent|
  parent_plate = Plate.find_by(name: parent) or raise "Cannot find parent plate #{parent.inspect}"
  AssetLink.create!(ancestor: parent_plate, descendant: FactoryGirl.create(:destination_transfer_plate, name: name))
end

Given /^the "([^\"]+)" transfer template has been used between "([^\"]+)" and "([^\"]+)"$/ do |template_name, source_name, destination_name|
  template    = TransferTemplate.find_by(name: template_name) or raise StandardError, "Could not find transfer template #{template_name.inspect}"
  source      = Plate.find_by(name: source_name)              or raise StandardError, "Could not find source plate #{source_name.inspect}"
  destination = Plate.find_by(name: destination_name)         or raise StandardError, "Could not find destination plate #{destination_plate.inspect}"
  template.create!(source: source, destination: destination, user: FactoryGirl.create(:user))
end

def assert_request_state(state, targets, direction, request_class)
  association = (direction == 'to') ? :requests_as_target : :requests_as_source
  assert_equal(
    [state],
    Array(targets).map(&association).flatten.select { |r| r.is_a?(request_class) }.map(&:state).uniq,
    "Some #{request_class.name} requests are in the wrong state"
  )
end

def change_request_state(state, targets, direction, request_class)
  association = (direction == 'to') ? :requests_as_target : :requests_as_source
  Request.where(id: Array(targets).map(&association).flatten.select { |r| r.is_a?(request_class) }.map(&:id)).update_all(state: state)
end

{
  'plate'                    => 'target.wells',
  'multiplexed library tube' => 'target'
}.each do |target, request_holder|
  line = __LINE__
  instance_eval(%Q{
    Then /^the state of all the transfer requests (to|from) (the #{target} .+) should be "([^"]+)"$/ do |direction, target, state|
      assert_request_state(state, #{request_holder}, direction, TransferRequest)
    end

    Then /^the state of all the pulldown library creation requests (to|from) (the #{target} .+) should be "([^"]+)"$/ do |direction, target, state|
      assert_request_state(state, #{request_holder}, direction, Pulldown::Requests::LibraryCreation)
    end

    Given /^the state of all the pulldown library creation requests (to|from) (the #{target} .+) is "([^"]+)"$/ do |direction, target, state|
      change_request_state(state, #{request_holder}, direction, Pulldown::Requests::LibraryCreation)
    end

    Then /^the state of all the illumina-b library creation requests (to|from) (the #{target} .+) should be "([^"]+)"$/ do |direction, target, state|
      assert_request_state(state, #{request_holder}, direction, IlluminaB::Requests::StdLibraryRequest)
    end

    Given /^the state of all the illumina-b library creation requests (to|from) (the #{target} .+) is "([^"]+)"$/ do |direction, target, state|
      change_request_state(state, #{request_holder}, direction, IlluminaB::Requests::StdLibraryRequest)
    end
  }, __FILE__, line)
end

Then /^the state of transfer requests (to|from) "([^\"]+)" on (the plate .+) should be "([^\"]+)"$/ do |direction, range, plate, state|
  plate.wells.select(&range.method(:include?)).each do |well|
    assert_request_state(state, well, direction, TransferRequest)
  end
end

Then /^the state of pulldown library creation requests (to|from) "([^\"]+)" on (the plate .+) should be "([^\"]+)"$/ do |direction, range, plate, state|
  plate.wells.select(&range.method(:include?)).each do |well|
    assert_request_state(state, well, direction, Pulldown::Requests::LibraryCreation)
  end
end

Given /the wells "([^\"]+)" on (the plate .+) are empty$/ do |range, plate|
  plate.wells.select(&range.method(:include?)).each { |well| well.aliquots.clear }
end

Then /^the study for the aliquots in the wells of (the plate .+) should match the last submission$/ do |plate|
  study = Submission.last.orders.first.study
  plate.wells.each { |w| w.aliquots.each { |a| assert_equal study, a.study } }
end
Given /^(the plate .+) is a "([^\"]+)"$/ do |plate, name|
  plate_purpose = PlatePurpose.find_by(name: name) or raise StandardError, "Cannot find the plate purpose #{name.inspect}"
  plate.update_attributes!(plate_purpose: plate_purpose)
end

Given /^transfers between "([^\"]+)" and "([^\"]+)" plates are done by "([^\"]+)" requests$/ do |source, destination, typename|
  source_plate_purpose      = PlatePurpose.find_by(name: source)      or raise StandardError, "Cannot find the plate purpose #{source.inspect}"
  destination_plate_purpose = PlatePurpose.find_by(name: destination) or raise StandardError, "Cannot find the plate purpose #{destination.inspect}"
  request_type              = RequestType.find_by(name: typename)     or raise StandardError, "Cannot find request type #{typename.inspect}"
  source_plate_purpose.child_relationships.create!(child: destination_plate_purpose, transfer_request_type: request_type)
end
