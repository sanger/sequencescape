# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {LotType}.
    #
    # A {LotType} governs the behaviour of a {Lot}
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/lot_types/` endpoint.
    #
    # @example GET request to fetch all lot types
    #   GET /api/v2/lot_types/
    #
    # @example GET request to fetch a specific lot type by ID
    #   GET /api/v2/lot_types/123/
    #
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class LotTypeResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The universally unique identifier (UUID) of the lot type.
      attribute :uuid, readonly: true

      # @!attribute [rw] name
      #   The name of this lot type
      #   @note This attribute must be unique.
      #   @todo This resource is immutable; Update attribute to be read-only.
      #   @return [String] The lot type name.
      attribute :name, write_once: true

      # @!attribute [r] template_class
      #   The class of the template associated with this lot type.
      attribute :template_class, read_only: true

      # @!attribute [rw] template_type
      #   The type of template associated with this lot type. This is derived dynamically based on the internal
      #   class name of the template.
      #   @todo This resource is immutable; Update attribute to be read-only.
      #   @return [String] The template type.
      attribute :template_type, write_once: true

      # @!attribute [r] qcable_name
      #   The name of the QCable associated with this lot type.
      attribute :qcable_name, read_only: true

      # @!attribute [r] printer_type
      #   The type of printer used for this lot type.
      #   This is retrieved from the LotType model.
      #   @return [String] The printer type.
      #   e.g. '96 Well Plate'
      attribute :printer_type, read_only: true

      ###
      # Getters and Setters
      ###

      # Retrieves the name of the target purpose associated with this lot type.
      # This is the type of labware that end up being created under this lot type.
      # The method (along with naming) was added for consistency with the v1 API
      # when converting Gatekeeper to use the v2 API.
      #
      # @return [String, nil] The name of the target purpose, or `nil` if no target purpose is set.
      # e.g. 'Tag Plate'
      def qcable_name
        target_purpose&.name
      end

      # Retrieves the template type based on the internal class name.
      #
      # @return [String] The template type
      # e.g 'TagLayoutTemplate'
      def template_type
        template_type = _model.template_class.underscore
        self.class._model_hints[template_type] || template_type
      end

      ###
      # Relationships
      ###

      # @!attribute [rw] target_purpose
      #   The {Purpose} that this lot type is associated with
      #   @todo This resource is immutable; Update relationship to be read-only.
      #   @return [PurposeResource] The associated purpose of this lot type.
      has_one :target_purpose, write_once: true, class_name: 'Purpose'

      ###
      # Filters
      ###

      # @!method active
      #   Filter to return only active lot types.
      #   This filter allows users to specify if only active lot types should be returned.
      #   @example Using the filter: `GET /api/v2/lot_types?active=true`
      #   @return [Boolean] Whether the lot type is active or not.
      filter :active, default: true
    end
  end
end
