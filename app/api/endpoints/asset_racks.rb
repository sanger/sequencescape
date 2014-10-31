class ::Endpoints::AssetRacks < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:asset_rack_purpose, :json => 'asset_rack_purpose')
  end

end
