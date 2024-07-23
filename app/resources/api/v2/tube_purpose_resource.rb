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
    end
  end
end
