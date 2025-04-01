# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Tag}.
    #
    # A {Tag} is a short, know sequence of DNA which gets applied to a sample.
    # The tag remains attached through subsequent processing, and means that it is
    # possible to identify the origin of a sample if multiple samples are subsequently
    # pooled together.
    # Tags are sometimes referred to as barcodes by our users.
    # Tag is stored on aliquot, and an individual aliquot can have two tags
    # identified as tag and tag2, these may also be known as i7 and i5 respectively.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/tags/` endpoint.
    #
    # @example GET request for all tags
    #   GET /api/v2/tags/
    #
    # @example GET request for a tag with ID 123
    #   GET /api/v2/tags/123/
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [rw] map_id
      #   The ID of the map associated with the tag. This attribute is write-once, meaning it cannot be updated after
      #   creation.
      #   @return [String] The ID of the associated map.
      #   @note This attribute is required when creating a tag.
      attribute :map_id, write_once: true

      # @!attribute [rw] oligo
      #   The oligo sequence associated with the tag. This attribute is write-once, meaning it cannot be updated after
      #   creation.
      #   @return [String] The oligo sequence associated with the tag.
      #   @note This attribute is required when creating a tag.
      attribute :oligo, write_once: true

      ###
      # Relationships
      ###

      # @!attribute [r] tag_group
      #   The relationship to the tag group associated with this tag. A tag belongs to one specific tag group.
      #   @return [Api::V2::TagGroupResource] The tag group associated with this tag.
      has_one :tag_group
    end
  end
end
