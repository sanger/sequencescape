TRANSFER_TYPES = [
  'between plates',
  'from plate to tube'
]

TRANSFER_TYPES_REGEXP = TRANSFER_TYPES.join('|')

def transfer_model(name)
  "transfer/#{name}".gsub(/\s+/, '_').camelize.constantize
end

Given /^the UUID for the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |model,id,uuid_value|
  set_uuid_for(transfer_model(model).find(id), uuid_value)
end

Given /^the transfer (between plates|from plate to tube) exists with ID (\d+)$/ do |name,id|
  Factory(:"transfer_#{name.gsub(/\s+/, '_')}", :id => id)
end

Given /^the UUID for the (source|destination) of the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |target, model, id, uuid_value|
  set_uuid_for(transfer_model(model).find(id).send(target), uuid_value)
end

Given /^the transfer template called "([^\"]+)" exists$/ do |name|
  Factory(:transfer_template, :name => name)
end

Then /^the transfers from plate (\d+) to plate (\d+) should be:$/ do |id1, id2, table|
  source, destination = Plate.find(id1), Plate.find(id2)
  table.hashes.each do |transfers|
    source_well_location, destination_well_location = transfers['source'], transfers['destination']

    source_well      = source.wells.located_at(source_well_location).first           or raise StandardError, "Plate #{source.id} does not have well #{source_well_location.inspect}"
    destination_well = destination.wells.located_at(destination_well_location).first or raise StandardError, "Plate #{destination.id} does not have well #{destination_well_location.inspect}"
    assert_not_nil(TransferRequest.between(source_well, destination_well).first, "No transfer between #{source_well_location.inspect} and #{destination_well_location.inspect}")
  end
end

Given /^a transfer plate exists with ID (\d+)$/ do |id|
  Factory(:transfer_plate, :id => id)
end

Given /^the "([^\"]+)" transfer template has been used between "([^\"]+)" and "([^\"]+)"$/ do |template_name, source_name, destination_name|
  template    = TransferTemplate.find_by_name(template_name) or raise StandardError, "Could not find transfer template #{template_name.inspect}"
  source      = Plate.find_by_name(source_name)              or raise StandardError, "Could not find source plate #{source_name.inspect}"
  destination = Plate.find_by_name(destination_name)         or raise StandardError, "Could not find destination plate #{destination_plate.inspect}"
  template.create!(:source => source, :destination => destination)
end


def assert_request_state(state, targets, direction, request_class)
  association = (direction == 'to') ? :requests_as_target : :requests_as_source
  assert_equal(
    [ state ],
    Array(targets).map(&association).flatten.select { |r| r.is_a?(request_class) }.map(&:state).uniq,
    "Some #{request_class.name} requests are in the wrong state"
  )
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
      assert_request_state(state, #{request_holder}, direction, PulldownLibraryCreationRequest)
    end
  }, __FILE__, line)
end
