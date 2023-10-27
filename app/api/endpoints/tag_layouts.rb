# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for TagLayouts
class Endpoints::TagLayouts < Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance { belongs_to(:plate, json: 'plate') }
end
