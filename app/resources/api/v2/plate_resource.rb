# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Plate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PlateResource < BaseResource
      # We import most labware shared behaviour, this includes associations,
      # attributes and filters
      # Before adding behaviour here, consider if they can be applied to ALL
      # labware
      include Api::V2::SharedBehaviour::Labware

      # Constants...

      # immutable # comment to make the resource mutable

      default_includes :uuid_object, :barcodes, :plate_purpose, :transfer_requests

      # Associations:
      has_many :wells

      # Attributes
      attribute :number_of_rows, readonly: true, delegate: :height
      attribute :number_of_columns, readonly: true, delegate: :width
      attribute :size, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
