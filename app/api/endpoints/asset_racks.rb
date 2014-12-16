class ::Endpoints::AssetRacks < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:asset_rack_purpose, :json => 'asset_rack_purpose')
    has_many(:strip_tubes, :json => 'strip_tubes', :to => 'strip_tubes', :scoped => 'include_wells')
  end

end
