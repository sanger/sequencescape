# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for ReferenceGenomes
class Endpoints::ReferenceGenomes < ::Core::Endpoint::Base
  model { action(:create, to: :standard_create!) }

  instance { action(:update, to: :standard_update!) }
end
