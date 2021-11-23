# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for CustomMetadatumCollections
class Endpoints::CustomMetadatumCollections < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:asset, json: 'asset', to: 'asset')
    belongs_to(:user, json: 'user', to: 'user')
    action(:update, to: :standard_update!)
  end
end
