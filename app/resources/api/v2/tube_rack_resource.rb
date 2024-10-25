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
      # Constants...

      # TODO: Here be dragons! This resource is mutable and can be created via
      #       the JSON API. However the asset_creation record is not generated
      #       as we would be relying on the request to tell us who requested it.
      #       Instead this should be done as part of adding authentication to
      #       the API in the security OKR.

      # model_name / model_hint if required

      default_includes :uuid_object, :barcodes

      # Associations:
      has_many :racked_tubes
      has_many :comments, readonly: true
      # TODO: change to purpose_id
      has_one :purpose, foreign_key: :plate_purpose_id, class_name: 'TubeRackPurpose'
      has_many :parents, readonly: true, polymorphic: true
      has_many :state_changes, readonly: true
      has_one :custom_metadatum_collection, foreign_key_on: :related
      has_many :ancestors, readonly: true, polymorphic: true
      # NB. no child or descendent associations as tube racks can't have children (tubes have children).
      # NB. no direct_submissions association as tube racks are currently not submitted.

      # Attributes
      attribute :uuid, readonly: true
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :labware_barcode, readonly: true
      attribute :state, readonly: true
      attribute :size
      attribute :number_of_rows, readonly: true
      attribute :number_of_columns, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :tube_locations

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
      # TODO: do we need scope for include_used? no direct child labwares here so would have to check for racked tubes

      # Class method overrides
      def fetchable_fields
        super - [:tube_locations]
      end

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

      # Custom methods
      # These shouldn't be used for business logic, and are more about
      # I/O and isolating implementation details.
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
