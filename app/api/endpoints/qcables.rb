# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Qcables
class Endpoints::Qcables < ::Core::Endpoint::Base
  model {}

  instance do
    belongs_to(:asset, json: 'asset')
    belongs_to(:lot, json: 'lot')
  end
end
