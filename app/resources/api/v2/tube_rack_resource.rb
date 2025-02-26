# frozen_string_literal: true

module Api
  module V2
    # @note Access this resource via the `/api/v2/tube_racks/` endpoint.
    #
    # Provides a JSON:API representation of {TubeRack}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeRackResource < BaseResource
      # NB. This resource is mutable and can be created via the JSON API.

      default_includes :uuid_object, :barcodes

      # Relationships
      has_many :comments, readonly: true
      has_many :racked_tubes
      # TODO: refactor plate_purpose_id to purpose_id throughout repo
      has_one :purpose, foreign_key: :plate_purpose_id, class_name: 'TubeRackPurpose'
      has_many :parents, readonly: true, polymorphic: true
      has_many :state_changes, readonly: true
      has_one :custom_metadatum_collection, foreign_key_on: :related
      has_many :ancestors, readonly: true, polymorphic: true
      # TODO: do we need descendants? might have to delegate to racked tubes

      # Attributes
      attribute :labware_barcode, write_once: true
      attribute :size, write_once: true
      attribute :number_of_rows, write_once: true
      attribute :number_of_columns, write_once: true
      attribute :name, delegate: :display_name, write_once: true
      attribute :tube_locations, writeonly: true
      attribute :uuid, readonly: true
      attribute :state, readonly: true

      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   purpose = TubeRack::Purpose.find_by(name: value)
                   records.where(plate_purpose_id: purpose)
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :created_at_gt,
             apply: lambda { |records, value, _options| records.where('labware.created_at > ?', value[0].to_date) }
      filter :updated_at_gt,
             apply: lambda { |records, value, _options| records.where('labware.updated_at > ?', value[0].to_date) }
      # TODO: do we need scope for include_used? would have to delegate to racked tubes

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
