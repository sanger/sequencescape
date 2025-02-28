# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PreCapturePool}.
    #
    # This resource represents a pre-capture pooling process, typically used in sequencing workflows
    # where samples are combined before the capture step. It provides a unique identifier (`uuid`) for tracking.
    #
    # @note Access this resource via the `/api/v2/pre_capture_pools/` endpoint.
    #
    # @example GET request to fetch all pre-capture pools
    #   GET /api/v2/pre_capture_pools/
    #
    # @example GET request to fetch a pre-capture pool
    #   GET /api/v2/pre_capture_pools/{id}
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PreCapturePoolResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   The UUID of the pre-capture pool.
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String]
      attribute :uuid, readonly: true
    end
  end
end
