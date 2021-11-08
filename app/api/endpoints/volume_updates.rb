# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for VolumeUpdates
class Endpoints::VolumeUpdates < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance { belongs_to(:target, json: 'target') }
end
