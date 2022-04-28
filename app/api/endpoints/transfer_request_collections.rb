# frozen_string_literal: true
module Endpoints
  class TransferRequestCollections < ::Core::Endpoint::Base
    model { action(:create, to: :standard_create!) }

    instance { belongs_to(:user, json: 'user') }
  end
end
