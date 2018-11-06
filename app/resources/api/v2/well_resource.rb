# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class WellResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      default_includes :uuid_object, :map, :transfer_requests_as_target, plate: :barcodes

      # Associations:
      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true
      has_many :qc_results, readonly: true
      has_many :requests_as_source, readonly: true
      has_many :requests_as_target, readonly: true
      has_many :aliquots, readonly: true
      has_many :downstream_assets, readonly: true, polymorphic: true

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :position, readonly: true
      attribute :state, readonly: true

      # Filters

      # Custom methods

      def position
        {
          'name' => _model.map_description
        }
      end

      # Class method overrides
    end
  end
end
