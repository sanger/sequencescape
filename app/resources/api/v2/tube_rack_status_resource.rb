# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TubeRackStatus}.
    #
    # A TubeRackStatus stores the status of the creation process of tube racks
    #
    # @note Access this resource via the `/api/v2/tube_rack_statuses/` endpoint.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    #
    # @example GET request for all TubeRackStatus resources
    #   GET /api/v2/tube_rack_statuses/
    #
    # @example GET request for a TubeRackStatus with ID 123
    #   GET /api/v2/tube_rack_statuses/123/
    #
    # @todo This resource is read-only; it can be accessed via GET requests, but creation or
    #   modification is not allowed. Should this resource be made immutable?
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    class TubeRackStatusResource < BaseResource
      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the tube rack status resource.
      #   @note This attribute is required for identifying the tube rack status.
      attribute :uuid, readonly: true
    end
  end
end
