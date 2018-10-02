RequestType.create_asset

RequestType.create!(
  asset_type: 'LibraryTube',
  for_multiplexing: true,
  initial_state: 'pending',
  key: 'external_multiplexed_library_creation',
  order: 0,
  name: 'External Multiplexed Library Creation',
  request_class_name: 'ExternalLibraryCreationRequest',
  request_purpose: :standard
)
