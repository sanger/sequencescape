# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of TransferRequest
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TransferRequestsAsTargetResource < BaseResource
      model_name 'TransferRequest'
    end
  end
end
