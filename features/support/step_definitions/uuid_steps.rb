# frozen_string_literal: true

def set_uuid_for(object, uuid_value)
  uuid = object.uuid_object
  uuid ||= object.build_uuid_object
  uuid.external_id = uuid_value
  uuid.save(validate: false)
end

ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME = [
  'sample',
  'study',
  'labware',
  'project',
  'sample tube',
  'library tube',
  'pulldown multiplexed library tube',
  'multiplexed library tube',
  'stock multiplexed library tube',
  'PacBio library tube',
  'well',
  'plate',
  'project',
  'submission template',
  'asset group',
  'request type',
  'search',
  'control plate',
  'dilution plate',
  'gel dilution plate',
  'pico assay a plate',
  'pico assay b plate',
  'pico assay plate',
  'pico dilution plate',
  'plate purpose',
  'purpose',
  'plate',
  'sequenom qc plate',
  'working dilution plate',
  'pipeline',
  'supplier',
  'transfer template',
  'tag layout template',
  'tag 2 layout template',
  'barcode printer',
  'tube',
  'tag group',
  'robot',
  'reference genome'
].freeze

SINGULAR_MODELS_BASED_ON_NAME_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME.join('|')
PLURAL_MODELS_BASED_ON_NAME_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME.map(&:pluralize).join('|')

# This may create invalid UUID external_id values but it means that we don't have to conform to the
# standard in our features.
# rubocop:todo Layout/LineLength
Given /^the UUID for the (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) "([^"]+)" is "([^"]+)"$/o do |model, name, uuid_value|
  # rubocop:enable Layout/LineLength
  object = model.gsub(/\s+/, '_').classify.constantize.find_by(name:) or
    raise "Cannot find #{model} #{name.inspect}"
  set_uuid_for(object, uuid_value)
end

# This may create invalid UUID external_id values but it means that we don't have to conform to the
# standard in our features.
# rubocop:todo Layout/LineLength
Given /^the UUID for the receptacle in (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) "([^"]+)" is "([^"]+)"$/o do |model, name, uuid_value|
  # rubocop:enable Layout/LineLength
  object = model.gsub(/\s+/, '_').classify.constantize.find_by(name:) or
    raise "Cannot find #{model} #{name.inspect}"
  set_uuid_for(object.receptacle, uuid_value)
end

# rubocop:todo Layout/LineLength
Given /^an? (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) called "([^"]+)" with UUID "([^"]+)"$/o do |model, name, uuid_value|
  # rubocop:enable Layout/LineLength
  set_uuid_for(FactoryBot.create(model.gsub(/\s+/, '_').to_sym, name:), uuid_value)
end

Given /^a tube purpose called "([^"]+)" with UUID "([^"]+)"$/ do |name, uuid_value|
  set_uuid_for(FactoryBot.create(:tube_purpose, name:), uuid_value)
end

Given /^an? (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) called "([^"]+)" with ID (\d+)$/o do |model, name, id|
  FactoryBot.create(model.gsub(/\s+/, '_').to_sym, name:, id:)
end

# rubocop:todo Layout/LineLength
Given /^(\d+) (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}) exist with names based on "([^"]+)" and IDs starting at (\d+)$/o do |count, model, name, id|
  # rubocop:enable Layout/LineLength
  (0...count.to_i).each do |index|
    step("a #{model.singularize} called \"#{name}-#{index + 1}\" with ID #{id.to_i + index}")
  end
end

Given /^(\d+) (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}) exist with names based on "([^"]+)"$/o do |count, model, name|
  (0...count.to_i).each { |index| step("a #{model.singularize} called \"#{name}-#{index + 1}\"") }
end

ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID = [
  'request',
  'library creation request',
  'multiplexed library creation request',
  'sequencing request',
  'user',
  'asset rack',
  'full asset rack',
  'asset rack creation',
  'sample tube',
  'lane',
  'plate',
  'receptacle',
  'well',
  'pulldown multiplexed library tube',
  'multiplexed library tube',
  'stock multiplexed library tube',
  'asset audit',
  'plate purpose',
  'purpose',
  'dilution plate purpose',
  'bulk transfer',
  'sample',
  'sample manifest',
  'submission',
  'order',
  'batch',
  'tag layout',
  'tag 2 layout',
  'tag2 layout template',
  'plate creation',
  'plate conversion',
  'tube creation',
  'state change',
  'aliquot',
  'qcable',
  'stock',
  'stamp',
  'qcable creator',
  'lot',
  'lot type',
  'robot',
  'qc decision',
  'robot',
  'reference genome',
  'transfer',
  'volume update'
].freeze

SINGULAR_MODELS_BASED_ON_ID_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID.join('|')
PLURAL_MODELS_BASED_ON_ID_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID.map(&:pluralize).join('|')

# rubocop:todo Layout/LineLength
Given /^a (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}|#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) with UUID "([^"]*)" exists$/o do |model, uuid_value|
  # rubocop:enable Layout/LineLength
  set_uuid_for(FactoryBot.create(model.gsub(/\s+/, '_').to_sym), uuid_value)
end

# rubocop:todo Layout/LineLength
Given /^the UUID for the last (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}|#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) is "([^"]+)"$/o do |model, uuid_value|
  # rubocop:enable Layout/LineLength
  set_uuid_for(model.gsub(/\s+/, '_').camelize.constantize.last, uuid_value)
end

# rubocop:todo Layout/LineLength
Given /^the UUID for the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) with ID (\d+) is "([^"]+)"$/o do |model, id, uuid_value|
  # rubocop:enable Layout/LineLength
  set_uuid_for(model.gsub(/\s+/, '_').camelize.constantize.find(id), uuid_value)
end

# rubocop:todo Layout/LineLength
Given /^all (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}|#{PLURAL_MODELS_BASED_ON_ID_REGEXP}) have sequential UUIDs based on "([^"]+)"$/o do |model, core_uuid|
  # rubocop:enable Layout/LineLength
  core_uuid = core_uuid.dup # Oh the irony of modifying a string that then alters Cucumber output!
  core_uuid << '-' if core_uuid.length == 23
  core_uuid << "%0#{36 - core_uuid.length}d"

  model
    .singularize
    .gsub(/\s+/, '_')
    .camelize
    .constantize
    .all
    .each_with_index { |object, index| set_uuid_for(object, core_uuid % (index + 1)) }
end

Given /^all sample tubes have receptacles with sequential UUIDs based on "([^"]+)"$/ do |core_uuid|
  core_uuid = core_uuid.dup # Oh the irony of modifying a string that then alters Cucumber output!
  core_uuid << '-' if core_uuid.length == 23
  core_uuid << "%0#{36 - core_uuid.length}d"

  SampleTube.all.each_with_index { |object, index| set_uuid_for(object.receptacle, core_uuid % (index + 1)) }
end

Given /^the UUID of the next (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) created will be "([^"]+)"$/o do |model, uuid_value|
  model_class = model.gsub(/\s+/, '_').classify.constantize
  Uuid.store_for_tests ||= UuidStore.new
  Uuid.store_for_tests.next_uuid_for(model_class.base_class, uuid_value)
end

Given /^the samples in manifest (\d+) have sequential UUIDs based on "([^"]+)"$/ do |id, core_uuid|
  core_uuid = core_uuid.dup # Oh the irony of modifying a string that then alters Cucumber output!
  core_uuid << '-' if core_uuid.length == 23
  core_uuid << "%0#{36 - core_uuid.length}d"

  SampleManifest.find(id).samples.each_with_index { |object, index| set_uuid_for(object, core_uuid % (index + 1)) }
end

Given /^the UUID of the last (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) created is "([^"]+)"$/o do |model, uuid_value|
  target = model.gsub(/\s+/, '_').classify.constantize.last or
    raise StandardError, "There appear to be no #{model.pluralize}"
  target.uuid_object.update!(external_id: uuid_value)
end

# TODO: It's 'UUID' not xxxing 'uuid'.
Given /^I have an (event|external release event) with uuid "([^"]*)"$/ do |model, uuid_value|
  set_uuid_for(
    model.gsub(/\s+/, '_').downcase.gsub(/[^\w]+/, '_').camelize.constantize.create!(message: model),
    uuid_value
  )
end

Given /^a (plate|well) with uuid "([^"]*)" exists$/ do |model, uuid_value|
  set_uuid_for(FactoryBot.create(model.to_sym), uuid_value)
end

Given /^the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) exists with ID (\d+)$/o do |model, id|
  FactoryBot.create(model.gsub(/\s+/, '_').to_sym, id:)
end

# rubocop:todo Layout/LineLength
Given /^the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) exists with ID (\d+) and the following attributes:$/o do |model, id, table|
  # rubocop:enable Layout/LineLength
  attributes = table.hashes.inject({}) { |h, att| h.update(att['name'] => att['value']) }
  attributes[:id] ||= id
  FactoryBot.create(model.gsub(/\s+/, '_').to_sym, attributes)
end

# rubocop:todo Layout/LineLength
Given /^a asset_link with uuid "([^"]*)" exists and connects "([^"]*)" and "([^"]*)"$/ do |uuid_value, uuid_plate, uuid_well|
  # rubocop:enable Layout/LineLength
  plate = Plate.find(Uuid.find_id(uuid_plate))
  well = Well.find(Uuid.find_id(uuid_well))
  set_uuid_for(AssetLink.create!(ancestor: plate, descendant: well), uuid_value)
end

Given /^there are (\d+) "([^"]+)" requests with IDs starting at (\d+)$/ do |count, type, id|
  (0...count.to_i).each { |index| step("a \"#{type}\" request with ID #{id.to_i + index}") }
end

Given /^a "([^"]+)" request with ID (\d+)$/ do |type, id|
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"

  # TODO: This is wrong.
  request_type.requests.create! do |r|
    r.id = id.to_i
    r.request_purpose = request_type.request_purpose
  end
end

Given /^all of the requests have appropriate assets with samples$/ do
  Request.find_each do |request|
    request.update!(asset: FactoryBot.create(request.request_type.asset_type.underscore.to_sym))
  end
end

Given /^plate "([^"]*)" is a source plate of "([^"]*)"$/ do |source_plate_uuid, destination_plate_uuid|
  source_plate = Plate.find(Uuid.find_id(source_plate_uuid))
  destination_plate = Plate.find(Uuid.find_id(destination_plate_uuid))
  source_plate.children << destination_plate
end
