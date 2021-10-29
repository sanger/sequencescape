# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for QcableCreators
class Endpoints::QcableCreators < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:user, json: 'user')
    belongs_to(:lot, json: 'lot')
    has_many(:qcables, json: 'qcables', to: 'qcables')
  end
end
