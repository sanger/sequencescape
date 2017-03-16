# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

def set_uuid_for(object, uuid_value)
  uuid   = object.uuid_object
  uuid ||= object.build_uuid_object
  uuid.external_id = uuid_value
  uuid.save(validate: false)
end

ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME = [
  'sample',
  'study',
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
]

SINGULAR_MODELS_BASED_ON_NAME_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME.join('|')
PLURAL_MODELS_BASED_ON_NAME_REGEXP   = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_NAME.map(&:pluralize).join('|')

# This may create invalid UUID external_id values but it means that we don't have to conform to the
# standard in our features.
Given /^the UUID for the (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) "([^\"]+)" is "([^\"]+)"$/ do |model, name, uuid_value|
  object = model.gsub(/\s+/, '_').classify.constantize.find_by(name: name) or raise "Cannot find #{model} #{name.inspect}"
  set_uuid_for(object, uuid_value)
end

Given /^an? (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) called "([^\"]+)" with UUID "([^\"]+)"$/ do |model, name, uuid_value|
  set_uuid_for(FactoryGirl.create(model.gsub(/\s+/, '_').to_sym, name: name), uuid_value)
end

Given /^a tube purpose called "([^\"]+)" with UUID "([^\"]+)"$/ do |name, uuid_value|
  set_uuid_for(FactoryGirl.create(:tube_purpose, name: name), uuid_value)
end

Given /^an? (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}) called "([^\"]+)" with ID (\d+)$/ do |model, name, id|
  FactoryGirl.create(model.gsub(/\s+/, '_').to_sym, name: name, id: id)
end

Given /^(\d+) (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}) exist with names based on "([^\"]+)" and IDs starting at (\d+)$/ do |count, model, name, id|
  (0...count.to_i).each do |index|
    step(%Q{a #{model.singularize} called "#{name}-#{index + 1}" with ID #{id.to_i + index}})
  end
end

Given /^(\d+) (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}) exist with names based on "([^\"]+)"$/ do |count, model, name|
  (0...count.to_i).each do |index|
    step(%Q{a #{model.singularize} called "#{name}-#{index + 1}"})
  end
end

ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID = [
  'request',
  'library creation request',
  'multiplexed library creation request',
  'sequencing request',

  'user',
  'asset',
  'asset rack',
  'full asset rack',
  'asset rack creation',
  'sample tube',
  'lane',
  'plate',
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
]

SINGULAR_MODELS_BASED_ON_ID_REGEXP = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID.join('|')
PLURAL_MODELS_BASED_ON_ID_REGEXP   = ALL_MODELS_THAT_CAN_HAVE_UUIDS_BASED_ON_ID.map(&:pluralize).join('|')

Given /^a (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}|#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) with UUID "([^"]*)" exists$/ do |model, uuid_value|
  set_uuid_for(FactoryGirl.create(model.gsub(/\s+/, '_').to_sym), uuid_value)
end

Given /^the UUID for the last (#{SINGULAR_MODELS_BASED_ON_NAME_REGEXP}|#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) is "([^\"]+)"$/ do |model, uuid_value|
  set_uuid_for(model.gsub(/\s+/, '_').camelize.constantize.last, uuid_value)
end

Given /^the UUID for the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |model, id, uuid_value|
  set_uuid_for(model.gsub(/\s+/, '_').camelize.constantize.find(id), uuid_value)
end

Given /^all (#{PLURAL_MODELS_BASED_ON_NAME_REGEXP}|#{PLURAL_MODELS_BASED_ON_ID_REGEXP}) have sequential UUIDs based on "([^\"]+)"$/ do |model, core_uuid|
  core_uuid = core_uuid.dup  # Oh the irony of modifying a string that then alters Cucumber output!
  core_uuid << '-' if core_uuid.length == 23
  core_uuid << "%0#{36 - core_uuid.length}d"

  model.singularize.gsub(/\s+/, '_').camelize.constantize.all.each_with_index do |object, index|
    set_uuid_for(object, core_uuid % (index + 1))
  end
end

Given /^the UUID of the next (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) created will be "([^\"]+)"$/ do |model, uuid_value|
  model_class = model.gsub(/\s+/, '_').classify.constantize
  Uuid.store_for_tests ||= UuidStore.new
  Uuid.store_for_tests.next_uuid_for(model_class.base_class, uuid_value)
end

Given /^the samples in manifest (\d+) have sequential UUIDs based on "([^\"]+)"$/ do |id, core_uuid|
  core_uuid = core_uuid.dup  # Oh the irony of modifying a string that then alters Cucumber output!
  core_uuid << '-' if core_uuid.length == 23
  core_uuid << "%0#{36 - core_uuid.length}d"

  SampleManifest.find(id).samples.each_with_index do |object, index|
    set_uuid_for(object, core_uuid % (index + 1))
  end
end

Given /^the UUID of the last (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) created is "([^\"]+)"$/ do |model, uuid_value|
  target = model.gsub(/\s+/, '_').classify.constantize.last or raise StandardError, "There appear to be no #{model.pluralize}"
  target.uuid_object.update_attributes!(external_id: uuid_value)
end

Given /^(\d+) (#{PLURAL_MODELS_BASED_ON_ID_REGEXP}) exist with IDs starting at (\d+)$/ do |count, model, id|
  (0...count.to_i).each do |index|
    step("the #{model.singularize} exists with ID #{id.to_i + index}")
  end
end

# TODO: It's 'UUID' not xxxing 'uuid'.
Given /^I have an (event|external release event) with uuid "([^"]*)"$/ do |model, uuid_value|
  set_uuid_for(model.gsub(/\s+/, '_').downcase.gsub(/[^\w]+/, '_').camelize.constantize.create!(message: model), uuid_value)
end

Given /^a (plate|well) with uuid "([^"]*)" exists$/ do |model, uuid_value|
  set_uuid_for(FactoryGirl.create(model.to_sym), uuid_value)
end

Given /^the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) exists with ID (\d+)$/ do |model, id|
  FactoryGirl.create(model.gsub(/\s+/, '_').to_sym, id: id)
end

Given /^the (#{SINGULAR_MODELS_BASED_ON_ID_REGEXP}) exists with ID (\d+) and the following attributes:$/ do |model, id, table|
  attributes = table.hashes.inject({}) { |h, att| h.update(att['name'] => att['value']) }
  attributes[:id] ||= id
  FactoryGirl.create(model.gsub(/\s+/, '_').to_sym, attributes)
end

Given /^a asset_link with uuid "([^"]*)" exists and connects "([^"]*)" and "([^"]*)"$/ do |uuid_value, uuid_plate, uuid_well|
  plate = Plate.find(Uuid.find_id(uuid_plate))
  well  = Well.find(Uuid.find_id(uuid_well))
  set_uuid_for(AssetLink.create!(ancestor: plate, descendant: well), uuid_value)
end

Given /^there are (\d+) "([^\"]+)" requests with IDs starting at (\d+)$/ do |count, type, id|
  (0...count.to_i).each do |index|
    step(%Q{a "#{type}" request with ID #{id.to_i + index}})
  end
end

Given /^a "([^\"]+)" request with ID (\d+)$/ do |type, id|
  request_type = RequestType.find_by(name: type) or raise StandardError, "Cannot find request type #{type.inspect}"
  # TODO: This is wrong.
  request_type.requests.create! { |r| r.id = id.to_i; r.request_purpose = request_type.request_purpose }
end

Given /^all of the requests have appropriate assets with samples$/ do
  Request.find_each do |request|
    request.update_attributes!(asset: FactoryGirl.create(request.request_type.asset_type.underscore.to_sym))
  end
end

Given /^plate "([^"]*)" is a source plate of "([^"]*)"$/ do |source_plate_uuid, destination_plate_uuid|
  source_plate = Plate.find(Uuid.find_id(source_plate_uuid))
  destination_plate = Plate.find(Uuid.find_id(destination_plate_uuid))
  source_plate.children << destination_plate
end

Given /^the UUID for well (\d+) on plate "(.*?)" is "(.*?)"$/ do |well_id, plate_name, uuid|
  plate = Plate.find_by(name: plate_name) || Plate.find_by(barcode: plate_name)
  set_uuid_for(plate.wells[well_id.to_i - 1], uuid)
end
