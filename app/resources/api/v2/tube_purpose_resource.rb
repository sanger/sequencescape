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
      attribute :purpose_type

      # @!attribute [rw]
      # @return [String] The target type.
      attribute :target_type

      #####
      # Custom getters and setters
      #####

      # Gets the purpose type from the model.
      # @return [String] The purpose type.
      def purpose_type
        @model.type
      end

      # Set the purpose type on the model.
      # @param [String] value The purpose type to set.
      # @return [void]
      def purpose_type=(value)
        @model.type = value
      end
    end
  end
end
