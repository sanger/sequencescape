# frozen_string_literal: true

module Api
  module V2
    module Transfer
      # Provides a JSON API controller for Transfers.
      # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
      class TransfersController < JSONAPI::ResourceController
        # By default JSONAPI::ResourceController provides most of the standard
        # behaviour, and in many cases this file may be left empty.
      end
    end
  end
end
