# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Lanes
class Endpoints::Lanes < ::Core::Endpoint::Base
  model {}

  instance { has_many(:requests, json: 'requests', to: 'requests') }
end
