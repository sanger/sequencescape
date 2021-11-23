# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Tag2Layouts
class Endpoints::Tag2Layouts < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance do
    belongs_to(:plate, json: 'plate')
    belongs_to(:source, json: 'source')
  end
end
