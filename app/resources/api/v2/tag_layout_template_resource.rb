# frozen_string_literal: true

module Api
  module V2
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

      has_one :tag_group
      has_one :tag2_group, class_name: 'TagGroup'

      ###
      # Attributes
      ###

      # @!attribute [r]
      # @return [String] The UUID of the tag layout template.
      attribute :uuid, readonly: true

      # @!attribute [r]
      # @return [String] The name of the tag layout template.
      attribute :name, readonly: true

      # @!attribute [r]
      # @return [String] The direction algorithm name for the tag layout template.
      attribute :direction, readonly: true

      # @!attribute [r]
      # @return [String] The walking_by algorithm name for the tag layout template.
      attribute :walking_by, readonly: true

      ###
      # Filters
      ###

      filter :enabled, default: true
    end
  end
end
