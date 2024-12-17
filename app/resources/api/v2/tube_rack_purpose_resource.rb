# frozen_string_literal: true

module Api
  module V2
    # This resource represents the API structure for the TubeRack::Purpose model.
    # This purpose is used by Limber for config generation.
    #
    # @note Access this resource via the `/api/v2/tube_rack_purposes/` endpoint.
    #
    # Provides a JSON:API representation of {TubeRack::Purpose}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeRackPurposeResource < BaseResource
      model_name 'TubeRack::Purpose'

      #####
      # Attributes
      #####

      # @!attribute [rw] name
      #   @return [String] the name of the tube rack purpose.
      attribute :name

      # @!attribute [rw] size
      #   @return [Integer] the size of the tube rack purpose.
      attribute :size

      # @!attribute [rw] purpose_type
      #   @return [String] the purpose type. This is mapped to the type attribute on the model.
      attribute :purpose_type, delegate: :type

      # @!attribute [rw] target_type
      #   @return [String] the target type.
      attribute :target_type

      # @!attribute [r] uuid
      #   @return [String] the UUID of the tube rack purpose.
      attribute :uuid, readonly: true

      # Gets the list of fields which are creatable on a TubeRackPurpose.
      #
      # @param _context [JSONAPI::Resource::Context] not used
      # @return [Array<Symbol>] the list of creatable fields.
      def self.creatable_fields(_context)
        super - %i[uuid] # Do not allow creating with any readonly fields
      end

      # Gets the list of fields which are updatable on an existing TubeRackPurpose.
      #
      # @param _context [JSONAPI::Resource::Context] not used
      # @return [Array<Symbol>] the list of updatable fields.
      def self.updatable_fields(_context)
        super - %i[uuid] # Do not allow creating with any readonly fields
      end

      filter :type, default: 'TubeRack::Purpose'

      filter :name
    end
  end
end
