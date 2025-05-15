# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PreCapturePool}.
    #
    # A pre-capture pool is a group of requests which will be pooled together midway
    # through library preparation, particularly prior to capture in the indexed-sequence
    # capture (ISC) pipelines
    # We build pre capture groups at submission so that they are not affected by failing of wells or
    # re-arraying.
    # See [Submissions in Sequencescape](https://ssg-confluence.internal.sanger.ac.uk/display/PSDPUB/Submissions+in+Sequencescape)
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
      default_includes :uuid_object

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
