# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Lots
class Endpoints::Lots < ::Core::Endpoint::Base
  model {}

  instance do
    has_many(:qcables, json: 'qcables', to: 'qcables')
    belongs_to(:lot_type, json: 'lot_type', to: 'lot_type')
    belongs_to(:template, json: 'template', to: 'template')
  end
end
