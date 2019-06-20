# Controls API V1 {::Core::Endpoint::Base endpoints} for VolumeUpdates
class ::Endpoints::VolumeUpdates < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:target, json: 'target')
  end
end
