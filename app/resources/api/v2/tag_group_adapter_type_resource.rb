# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TagGroup::AdapterType}

    # AdapterType is a property of a {TagGroup} which determines how the tag sequence
    # interacts with the Sequencing process. It is recorded in Sequencescape as it
    # can affect which processes a tag group is suitable for, and thus can be used
    # to filter lists of validate selections.
    #
    # @note Access this resource via the `/api/v2/tag_group_adapter_types/` endpoint.
    #
    # @example GET request for all tag group adapter types
    #   GET /api/v2/tag_group_adapter_types/
    #
    # @example GET request for a specific tag group adapter type by ID
    #   GET /api/v2/tag_group_adapter_types/123/
    #
    # @todo The below POST example is provided for reference, however it currently throws an error.
    #   This is because the `name` attribute is read-only in the resource, but a required field in the model.
    #
    # @example POST request to create a new tag group adapter type
    #   POST /api/v2/tag_group_adapter_types/
    #   {
    #     "data": {
    #       "type": "tag_group_adapter_types",
    #       "attributes": {
    #      //    "name": "Adapter Type Name"
    #       },
    #       "relationships": {
    #         "tag_groups": {
    #           "data": [
    #             { "type": "tag_groups", "id": "1" },
    #             { "type": "tag_groups", "id": "72" }
    #           ]
    #         }
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package used in Sequencescape.
    class TagGroupAdapterTypeResource < BaseResource
      model_name 'TagGroup::AdapterType'

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   The name of the adapter type, representing a specific category of sequencing adapters.
      #   This is a read-only attribute.
      #   @todo Should this be read-write?
      #   @return [String] The name of the adapter type.
      attribute :name, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [rw] tag_groups
      #   The tag groups associated with this adapter type.
      #   These tag groups define specific barcoding or indexing sequences used in sequencing workflows.
      #   This relationship is write-once, meaning it can be set during creation but not modified afterward.
      #   @return [Array<TagGroupResource>] A collection of tag groups linked to this adapter type.
      has_many :tag_groups, write_once: true, class_name: 'TagGroup'
    end
  end
end
