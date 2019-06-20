# Controls API V1 {::Core::Endpoint::Base endpoints} for AssetAudits
class ::Endpoints::AssetAudits < ::Core::Endpoint::Base
  model do
    action(:create) do |request, _response|
      request.create!
    end
  end

  instance do
    belongs_to(:asset, json: 'asset')
  end
end
