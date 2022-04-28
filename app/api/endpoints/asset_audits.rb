# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for AssetAudits
class Endpoints::AssetAudits < ::Core::Endpoint::Base
  model { action(:create) { |request, _response| request.create! } }

  instance { belongs_to(:asset, json: 'asset') }
end
