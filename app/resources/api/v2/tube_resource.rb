# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Tube
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TubeResource < BaseResource
      include Api::V2::SharedBehaviour::Labware

      # Constants...

      immutable # comment to make the resource mutable

      default_includes :uuid_object, :barcodes, :transfer_requests_as_target

      # Associations:
      has_many :aliquots, readonly: true
      has_many :transfer_requests_as_target, readonly: true
      has_one :receptacle, readonly: true, foreign_key_on: :related

      # Attributes

      # Filters

      # Class method overrides
    end
  end
end
