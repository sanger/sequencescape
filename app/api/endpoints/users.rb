# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for Users
class Endpoints::Users < ::Core::Endpoint::Base
  model {}

  instance { action(:update, to: :standard_update!) }
end
