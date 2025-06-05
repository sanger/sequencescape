# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {TubeRack}.
    #
    # This resource represents a tube rack, which can contain a collection of tubes, with locations specified
    #   for each tube in the rack.
    # Tubes are linked via the RackedTubes association
    #
    # @note Access this resource via the `/api/v2/tube_racks/` endpoint.
    #
    # @example GET request to fetch a Tube Rack by its ID:
    #   GET /api/v2/tube_racks/{id}/
    #
    # @example POST request to create a new Tube Rack with a name and barcode:
    #   POST /api/v2/tube_racks/
    #   {
    #     "data": {
    #       "type": "tube_racks",
    #       "attributes": {
    #           "size": 48,
    #           "name": "Rack A1",
    #           "tube_locations": {
    #               "A1": { "uuid": "558b931c-fb5f-11ef-86cc-000000000000" },
    #               "B1": { "uuid": "2abc4186-3718-11ec-9c4c-acde48001122" },
    #               "C1": { "uuid": "2ace27fc-3718-11ec-9c4c-acde48001122" }
    #           }
    #       }
    #     }
    #   }
    #
    # @example PATCH request to update the Tube Rack's size:
    #   PATCH /api/v2/tube_racks/123
    #   {
    #     "data": {
    #       "id": 123,
    #       "type": "tube_racks",
    #       "attributes": {
    #           "size": 96
    #       }
    #     }
    #   }
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TubeRackResource < BaseResource
      # NB. This resource is mutable and can be created via the JSON API.

      default_includes :uuid_object, :barcodes

      # Attributes
      # @!attribute [r] created_at
      #   @return [String] The timestamp when the tube rack was created. Readonly.
      attribute :created_at, readonly: true

      # @!attribute [rw] labware_barcode
      #   @note A POST request errors when this attribute is provided.
      #   @return [String] The barcode for the tube rack.
      #   @note This is a write-once attribute, meaning it cannot be modified once it has been set.
      attribute :labware_barcode, write_once: true

      # @!attribute [rw] name
      #   @return [String] The name of the tube rack.
      #   @note This is a write-once attribute, meaning it cannot be modified once it has been set.
      attribute :name, delegate: :display_name, write_once: true

      # @!attribute [rw] number_of_columns
      #   @note A POST request errors when this attribute is provided. I believe these are automatically
      #    calculated based on the size of the tube rack.
      #   @return [Integer] The number of columns in the tube rack.
      #   @note This is a write-once attribute, meaning it cannot be modified once it has been set.
      attribute :number_of_columns, write_once: true

      # @!attribute [rw] number_of_rows
      #   @note A POST request errors when this attribute is provided. I believe these are automatically
      #    calculated based on the size of the tube rack.
      #   @return [Integer] The number of rows in the tube rack.
      #   @note This is a write-once attribute, meaning it cannot be modified once it has been set.
      attribute :number_of_rows, write_once: true

      # @!attribute [rw] size
      #   @note This attribute is required.
      #   @return [String] The size of the tube rack (e.g., 48, 96).
      attribute :size, write_once: true

      # @!attribute [rw] tube_locations
      #   @note This is a write-only attribute used to map tubes to specific coordinates in the rack.
      #   @return [Void]
      #   @raise [RuntimeError] If any of the provided UUIDs do not correspond to a valid tube.
      #   @see #racked_tubes
      attribute :tube_locations, writeonly: true

      # @!attribute [r] updated_at
      #   @return [String] The timestamp when the tube rack was last updated. Readonly.
      attribute :updated_at, readonly: true

      # @!attribute [r] uuid
      #   @return [String] The unique identifier (UUID) of the tube rack.
      attribute :uuid, readonly: true

      # @!attribute [r] uuid
      #   @return [String] The state of the tube rack, derived from the transfer requests in the tubes.
      attribute :state, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] comments
      #   @return [CommentResource] A collection of comments related to the tube rack.
      #   @note Comments are readonly and provide additional context or notes regarding the tube rack.
      has_many :comments, readonly: true

      # @!attribute [rw] racked_tubes
      #   @return [RackedTubeResource] The tubes that have been placed in the tube rack.
      #   @note This relationship represents the tubes placed in the rack at specified coordinates.
      has_many :racked_tubes
      # TODO: refactor plate_purpose_id to purpose_id throughout repo
      has_one :purpose, foreign_key: :plate_purpose_id, class_name: 'TubeRackPurpose'
      has_many :parents, readonly: true, polymorphic: true
      has_many :state_changes, readonly: true
      has_one :custom_metadatum_collection, foreign_key_on: :related
      has_many :ancestors, readonly: true, polymorphic: true
      # TODO: do we need descendants? might have to delegate to racked tubes

      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true

      ###
      # Filters
      ###

      # @!method :barcode
      #   @example GET /api/v2/tube_racks?filter[barcode]=1234567890123
      #   @return [ActiveRecord::Relation] Filtered tube racks that match the provided barcode.
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }

      # @!method :uuid
      #   @example GET /api/v2/tube_racks?filter[uuid]=some-uuid-value
      #   @return [ActiveRecord::Relation] Filtered tube racks that match the provided UUID.
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # @!method :purpose_name
      #   @example GET /api/v2/tube_racks?filter[purpose_name]=Storage
      #   @return [ActiveRecord::Relation] Filtered tube racks that have the specified purpose name.
      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   purpose = TubeRack::Purpose.find_by(name: value)
                   records.where(plate_purpose_id: purpose)
                 end
               )

      # @!method :purpose_id
      #   @example GET /api/v2/tube_racks?filter[purpose_id]=12345
      #   @return [ActiveRecord::Relation] Filtered tube racks that have the specified purpose ID.
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :created_at_gt,
             apply: lambda { |records, value, _options| records.where('labware.created_at > ?', value[0].to_date) }
      filter :updated_at_gt,
             apply: lambda { |records, value, _options| records.where('labware.updated_at > ?', value[0].to_date) }
      # TODO: do we need scope for include_used? would have to delegate to racked tubes

      ###
      #  Field Methods
      ###

      # @note Tube locations are expected in the following format:
      #   { A1: { uuid: 'a1_tube_uuid' }, B1: { uuid: 'b1_tube_uuid' }, ... }
      # @param tube_locations [Hash] The locations of the tubes, with coordinates as keys (e.g., "A1")
      #   and tube UUIDs as values.
      # @raise [RuntimeError] If any tube UUID does not correspond to an existing tube.
      # @return [Void]
      #   This method assigns the tube locations for the rack, creating new RackedTube records as necessary.
      def tube_locations=(tube_locations)
        all_uuids = tube_locations.values.pluck(:uuid)
        tubes = Tube.with_uuid(all_uuids).index_by(&:uuid)
        tube_locations.each do |coordinate, tube|
          tube_uuid = tube[:uuid]
          raise "No tube found for UUID '#{tube_uuid}'" unless tubes.key?(tube_uuid)
          RackedTube.create(coordinate: coordinate, tube: tubes[tube_uuid], tube_rack: @model)
        end
      end

      # @note The labware barcode can be returned in different formats, such as EAN13 or machine-readable formats.
      # @return [Hash] A hash containing the different types of barcodes associated with the tube rack.
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
