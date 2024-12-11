# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/tube_racks/` endpoint.
    #
    # Provides a JSON:API representation of {TubeRack}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeRackResource < BaseResource
      # TODO: Here be dragons! This resource is mutable and can be created via
      #       the JSON API. However the asset_creation record is not generated
      #       as we would be relying on the request to tell us who requested it.
      #       Instead this should be done as part of adding authentication to
      #       the API in the security OKR.

      default_includes :uuid_object, :barcodes

      # Attributes
      attribute :created_at, readonly: true
      attribute :labware_barcode, write_once: true
      attribute :name, write_once: true
      attribute :number_of_columns, write_once: true
      attribute :number_of_rows, write_once: true
      attribute :size
      attribute :tube_locations, writeonly: true
      attribute :updated_at, readonly: true
      attribute :uuid, readonly: true

      # Relationships
      has_many :comments, readonly: true
      has_one :purpose, foreign_key: :plate_purpose_id
      has_many :racked_tubes

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   purpose = Purpose.find_by(name: value)
                   records.where(plate_purpose_id: purpose)
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }

      # Field Methods

      # Tube locations should be received as:
      # { A1: { uuid: 'a1_tube_uuid' }, B1: { uuid: 'b1_tube_uuid' }, ... }
      def tube_locations=(tube_locations)
        all_uuids = tube_locations.values.pluck(:uuid)
        tubes = Tube.with_uuid(all_uuids).index_by(&:uuid)
        tube_locations.each do |coordinate, tube|
          tube_uuid = tube[:uuid]
          raise "No tube found for UUID '#{tube_uuid}'" unless tubes.key?(tube_uuid)
          RackedTube.create(coordinate: coordinate, tube: tubes[tube_uuid], tube_rack: @model)
        end
      end

      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'machine_barcode' => _model.machine_barcode,
          'human_barcode' => _model.human_barcode
        }
      end
    end
  end
end
