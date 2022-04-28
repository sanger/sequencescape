# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a well
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class WellResource < BaseResource
      include Api::V2::SharedBehaviour::Receptacle

      # Constants...

      # immutable # uncomment to make the resource immutable

      default_includes :uuid_object, :map, :transfer_requests_as_target, plate: :barcodes

      # Associations:

      # Attributes
      attribute :position, readonly: true

      # Custom methods

      def position
        { 'name' => _model.map_description }
      end

      # Class method overrides
    end
  end
end
