# frozen_string_literal: true

Given /^a custom metadatum collection exists with ID (\d+)$/ do |id|
  metadata = [
    FactoryBot.build(:custom_metadatum, key: 'Key1', value: 'Value1'),
    FactoryBot.build(:custom_metadatum, key: 'Key2', value: 'Value2')
  ]
  FactoryBot.create(:custom_metadatum_collection, id: id, custom_metadata: metadata)
end

Given(/^the UUID for the custom metadatum collection with ID (\d+) is "(.*?)"$/) do |id, uuid|
  collection = CustomMetadatumCollection.find(id)
  set_uuid_for(collection, uuid)
  set_uuid_for(collection.asset, '00000000-1111-2222-3333-444444444445')
  set_uuid_for(collection.user, '00000000-1111-2222-3333-444444444446')
end

Given(/^the labware and the user exist and have UUID$/) do
  set_uuid_for(FactoryBot.create(:labware), '00000000-1111-2222-3333-444444444445')
  set_uuid_for(FactoryBot.create(:user), '00000000-1111-2222-3333-444444444446')
end
