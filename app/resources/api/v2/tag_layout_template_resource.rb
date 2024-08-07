# frozen_string_literal: true

module Api
  module V2
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    #
    # Provides a JSON:API representation of {TagLayoutTemplate}.
    # This resource can be accessed via the `/api/v2/tag_layout_templates/` endpoint.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TagLayoutTemplateResource < BaseResource
      immutable

      ###
      # Relationships
      ###

      # @!attribute [r] tag_group
      #    A relationship for the primary tag group associated with the tag layout template.
      #    @return [Api::V2::TagGroupResource]
      has_one :tag_group

      # @!attribute [r] tag2_group
      #    A relationship for the secondary tag group associated with the tag layout template.
      #    This is used during dual indexing, but will not be found during single indexing.
      #    @return [Api::V2::TagGroupResource]
      has_one :tag2_group, class_name: 'TagGroup'

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #    The UUID of the tag layout template.
      #    @return [String]
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #    The display name of the tag layout template.
      #    @return [String]
      attribute :name, readonly: true

      # @!attribute [r] direction
      #    The name of the algorithm defining the direction of the tag layout.
      #    @return [String]
      attribute :direction, readonly: true

      # @!attribute [r] walking_by
      #    The name of the algorithm defining the way of walking through the tag layout.
      #    @return [String]
      attribute :walking_by, readonly: true

      ###
      # Filters
      ###

      # @!method enabled
      #    A filter to return only enabled tag layout templates.
      #    Set by default to `true`.
      filter :enabled, default: true
    end
  end
end
