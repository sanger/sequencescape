RequestType.create!(
  :name => 'Create Asset', :key => 'create_asset', :order => 1,
  :asset_type => 'Asset', :multiples_allowed => false,
  :request_class_name => 'CreateAssetRequest', :morphology => RequestType::LINEAR
)
RequestType.create!(
  :name => 'Transfer', :key => 'transfer', :order => 1,
  :asset_type => 'Asset',  :multiples_allowed => false,
  :request_class_name => 'TransferRequest',  :morphology => RequestType::CONVERGENT,
  :for_multiplexing => 0, :billable => 0
)