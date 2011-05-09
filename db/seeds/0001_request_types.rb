RequestType.create!(
  :name => 'Create Asset', :key => 'create_asset', :order => 1, 
  :asset_type => 'Asset', :multiples_allowed => false,
  :request_class_name => 'CreateAssetRequest', :morphology => RequestType::LINEAR
)
