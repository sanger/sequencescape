# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Batches
class Endpoints::Batches < ::Core::Endpoint::Base
  model {}

  instance { belongs_to(:pipeline, json: 'pipeline') }
end
