# frozen_string_literal: true

TRANSFER_TYPES = ['between plates', 'from plate to tube'].freeze

TRANSFER_TYPES_REGEXP = TRANSFER_TYPES.join('|')

def transfer_model(name)
  "transfer/#{name}".gsub(/\s+/, '_').camelize.constantize
end

Given /^the UUID for the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^"]+)"$/o do |model, id, uuid_value|
  set_uuid_for(transfer_model(model).find(id), uuid_value)
end

Given /^the transfer (between plates|from plate to tube) exists with ID (\d+)$/ do |name, id|
  FactoryBot.create(:"transfer_#{name.gsub(/\s+/, '_')}", id:)
end

# rubocop:todo Layout/LineLength
Given /^the UUID for the (source|destination) of the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^"]+)"$/o do |target, model, id, uuid_value|
  # rubocop:enable Layout/LineLength
  set_uuid_for(transfer_model(model).find(id).send(target), uuid_value)
end

Given /^the ((?:pooling ||multiplex )?transfer template) called "([^"]+)" exists$/ do |type, name|
  FactoryBot.create(type.gsub(/\s/, '_').to_sym, name:)
end

Then 'the transfers from {plate_name} to {plate_name} should be:' do |source, destination, table|
  table.hashes.each do |transfers|
    source_well_location, destination_well_location = transfers['source'], transfers['destination']

    source_well = source.wells.located_at(source_well_location).first or
      raise StandardError, "Plate #{source.id} does not have well #{source_well_location.inspect}"
    destination_well = destination.wells.located_at(destination_well_location).first or
      raise StandardError, "Plate #{destination.id} does not have well #{destination_well_location.inspect}"
    assert_not_nil(
      TransferRequest.find_by(asset_id: source_well, target_asset_id: destination_well),
      "No transfer between #{source_well_location.inspect} and #{destination_well_location.inspect}"
    )
  end
end

Given /^a transfer plate exists with ID (\d+)$/ do |id|
  FactoryBot.create(:transfer_plate, id:)
end

Given /^a transfer plate called "([^"]+)" exists$/ do |name|
  FactoryBot.create(:transfer_plate, name:)
end

Given /^the plate "(.*?)" has additional wells$/ do |name|
  Plate
    .find_by(name:)
    .tap do |plate|
      plate.wells << %w[C1 D1].map do |location|
        map =
          Map
            .where_description(location)
            .where_plate_size(plate.size)
            .where_plate_shape(AssetShape.find_by(name: 'Standard'))
            .first or raise StandardError, "No location #{location} on plate #{plate.inspect}"
        FactoryBot.create(:tagged_well, map:)
      end
    end
end

Given /^a transfer plate called "([^"]+)" exists as a child of "([^"]+)"$/ do |name, parent|
  parent_plate = Plate.find_by!(name: parent)
  AssetLink.create!(ancestor: parent_plate, descendant: FactoryBot.create(:transfer_plate, name:))
end

Given(/^a transfer plate called "([^"]*)" exists as a child of plate (\d+)$/) do |name, parent_id|
  parent_plate = Plate.find(parent_id)
  AssetLink.create!(ancestor: parent_plate, descendant: FactoryBot.create(:transfer_plate, name:))
end

# rubocop:todo Layout/LineLength
Given /^the "([^"]+)" transfer template has been used between "([^"]+)" and "([^"]+)"$/ do |template_name, source_name, destination_name|
  # rubocop:enable Layout/LineLength
  template = TransferTemplate.find_by(name: template_name) or
    raise StandardError, "Could not find transfer template #{template_name.inspect}"
  source = Plate.find_by(name: source_name) or raise StandardError, "Could not find source plate #{source_name.inspect}"
  destination = Plate.find_by(name: destination_name) or
    raise StandardError, "Could not find destination plate #{destination_plate.inspect}"
  template.create!(source: source, destination: destination, user: FactoryBot.create(:user))
end

def assert_request_state(state, targets, direction, request_class)
  association = direction == 'to' ? :target_asset_id : :asset_id
  assert_equal(
    [state],
    request_class.where(association => targets).pluck(:state).uniq,
    "Some #{request_class.name} requests are in the wrong state"
  )
end

def change_request_state(state, targets, direction, request_class)
  association = direction == 'to' ? :requests_as_target : :requests_as_source
  Request.where(
    id: Array(targets).map(&association).flatten.select { |r| r.is_a?(request_class) }.map(&:id)
  ).update_all(state:)
end

# rubocop:todo Layout/LineLength
Then 'the state of all the {request_class} requests {direction} {uuid} should be {string}' do |request_class, direction, target, state|
  # rubocop:enable Layout/LineLength
  request_holder = target.try(:receptacles) || target
  assert_request_state(state, request_holder, direction, request_class)
end

# rubocop:todo Layout/LineLength
Then 'the state of all the {request_class} requests {direction} {asset_name} should be {string}' do |request_class, direction, target, state|
  # rubocop:enable Layout/LineLength
  request_holder = target.respond_to?(:wells) ? target.wells : target
  assert_request_state(state, request_holder, direction, request_class)
end

# rubocop:todo Layout/LineLength
Given 'the state of all the {request_class} requests {direction} {uuid} is {string}' do |request_class, direction, target, state|
  # rubocop:enable Layout/LineLength
  request_holder = target.respond_to?(:wells) ? target.wells : target
  change_request_state(state, request_holder, direction, request_class)
end

Then 'the state of all the transfer requests to {uuid} should be {string}' do |target, state|
  assert_equal target.transfer_requests_as_target.distinct.pluck(:state), [state]
end

Then 'the state of all the transfer requests to {asset_name} should be {string}' do |target, state|
  assert_equal target.transfer_requests_as_target.distinct.pluck(:state), [state]
end

Then 'the state of all the transfer requests from {uuid} should be {string}' do |target, state|
  assert_equal target.transfer_requests_as_source.distinct.pluck(:state), [state]
end

# rubocop:todo Layout/LineLength
Then 'the state of transfer requests {direction} {well_range} on {plate_name} should be {string}' do |direction, range, plate, state|
  # rubocop:enable Layout/LineLength
  plate
    .wells
    .select(&range.method(:include?))
    .each { |well| assert_request_state(state, well, direction, TransferRequest) }
end

# rubocop:todo Layout/LineLength
Then 'the state of {request_class} requests {direction} {well_range} on {plate_name} should be {string}' do |request_class, direction, range, plate, state|
  # rubocop:enable Layout/LineLength
  plate
    .wells
    .select(&range.method(:include?))
    .each { |well| assert_request_state(state, well, direction, request_class) }
end

Given 'the wells {well_range} on {plate_name} are empty' do |range, plate|
  plate.wells.select(&range.method(:include?)).each { |well| well.aliquots.clear }
end

Then 'the study for the aliquots in the wells of {uuid} should match the last submission' do |plate|
  study = Submission.last.orders.first.study
  plate.wells.includes(:aliquots).find_each { |w| w.aliquots.each { |a| assert_equal study.id, a.study_id } }
end
Given '{asset_name} is a {string}' do |plate, name|
  plate_purpose = Purpose.find_by!(name:)
  plate.update!(plate_purpose:)
end
