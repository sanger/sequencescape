# Controls API V1 {::Core::Endpoint::Base endpoints} for Lanes
class ::Endpoints::Lanes < ::Core::Endpoint::Base
  model do
  end

  instance do
    has_many(:requests, json: 'requests', to: 'requests')
  end
end
