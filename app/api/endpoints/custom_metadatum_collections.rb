
class ::Endpoints::CustomMetadatumCollections < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:asset, json: 'asset', to: 'asset')
    belongs_to(:user, json: 'user', to: 'user')
    action(:update, to: :standard_update!)
  end
end
