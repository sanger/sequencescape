# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a tube purpose.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TubePurposeResource < BaseResource
      model_name 'Tube::Purpose'

      #####
      # Attributes
      #####

      # @!attribute [rw]
      # @return [String] The name of the tube purpose.
      attribute :name

      # @!attribute [rw]
      # @return [String] The purpose type. This is mapped to the type attribute on the model.
      attribute :purpose_type, delegate: :type

      # @!attribute [rw]
      # @return [String] The target type.
      attribute :target_type

      # @!attribute [r]
      # @return [String] The UUID of the tube purpose.
      attribute :uuid

      # Gets the list of fields which are creatable on a TubePurpose.
      #
      # @param _context [JSONAPI::Resource::Context] not used
      # @return [Array<Symbol>] the list of creatable fields.
      def self.creatable_fields(_context)
        super - %i[uuid] # Do not allow creating with any readonly fields
      end

      # Gets the list of fields which are updatable on an existing TubePurpose.
      #
      # @param _context [JSONAPI::Resource::Context] not used
      # @return [Array<Symbol>] the list of updatable fields.
      def self.updatable_fields(_context)
        super - %i[uuid] # Do not allow creating with any readonly fields
      end
    end
  end
end
