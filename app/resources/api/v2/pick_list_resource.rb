# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PickList}.
    #
    # A {PickList} is a lightweight wrapper to provide a simplified interface
    # for automatically generating {Batch batches} for the {CherrypickPipeline}.
    # It is intended to isolate external applications from the implementation
    # and to provide an interface for eventually building a simplified means
    # for generating cherrypicks
    #
    # @note Access this resource via the `/api/v2/pick_lists/` endpoint.
    #
    # @example GET request to retrieve all pick lists
    #   GET /api/v2/pick_lists/
    #
    # @example GET request to retrieve a specific pick list by ID
    #   GET /api/v2/pick_lists/123/
    #
    # @example POST request to create a new pick list (receptacle-based picks)
    #   POST /api/v2/pick_lists/
    #   {
    #     "data": {
    #       "type": "pick_lists",
    #       "attributes": {
    #         "asynchronous": true,
    #         "pick_attributes": [{ "source_receptacle_id": 96, "study_id": 1, "project_id": 1 }]
    #       }
    #     }
    #   }

    # @example POST request to create a new pick list (labware-based picks)
    #   POST /api/v2/pick_lists/
    #   @example POST request to create a new pick list (labware-based picks)
    #     POST /api/v2/pick_lists/
    #     {
    #       "data": {
    #         "type": "pick_lists",
    #         "attributes": {
    #           asynchronous: true,
    #           "labware_pick_attributes": [
    #             { "source_labware_id": 1, "source_labware_barcode": "SQPD-9001", "study_id": 1, "project_id": 1 }
    #           ]
    #         }
    #       }
    #     }
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PickListResource < BaseResource
      ###
      # Constants
      ###

      # List of permitted attributes for pick creation based on receptacles.
      PERMITTED_PICK_ATTRIBUTES = %i[source_receptacle_id study_id project_id].freeze

      # List of permitted attributes for pick creation based on labware.
      PERMITTED_LABWARE_PICK_ATTRIBUTES = %i[source_labware_id source_labware_barcode study_id project_id].freeze

      ###
      # Attributes
      ###

      # @!attribute [r] created_at
      #   @note This timestamp is automatically assigned upon creation.
      #   @return [String] The timestamp indicating when the pick list was created.
      attribute :created_at, readonly: true

      # @!attribute [r] updated_at
      #   @note This timestamp is automatically updated upon modification.
      #   @return [String] The timestamp indicating when the pick list was last updated.
      attribute :updated_at, readonly: true

      # @!attribute [rw] state
      #   The current state of the pick list, indicating its processing status.
      #   @return [String] The pick list state.
      attribute :state, write_once: true

      # @!attribute [rw] links
      #   A collection of related links for navigation or reference.
      #   @todo this attribute should be read-only.
      #   @return [Hash] The related pick list links.
      attribute :links, write_once: true

      # @!attribute [rw] pick_attributes
      #   A list of attributes defining the picks within this pick list.
      #   @note `source_receptacle_id`, `study_id`, and `project_id` are required attributes
      #   @return [Array<Hash>] The attributes of the picks.
      attribute :pick_attributes

      # @!attribute [w] labware_pick_attributes
      #   A list of attributes defining the picks based on Labware
      #   This provides an alternative way to create picks by proving a Labware ID or barcode,
      #     instead of receptacle IDs.
      #   @note `source_labware_id` or `source_labware_barcode` must be provided
      #   @note `study_id`, and `project_id` are required attributes
      #   @see #labware_pick_attributes=
      attribute :labware_pick_attributes, writeonly: true

      # @!attribute [rw] asynchronous
      #   Indicates whether the pick list should be processed asynchronously.
      #   @return [Boolean] Whether the operation should be handled asynchronously.
      attribute :asynchronous

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # JSON API v1.0 doesn't have native support for creating nested resources
      # in a single request. In addition, as {PickList::Pick picks} are not backed
      # by real database records yet we could expect to run into issues anyway.
      # So we just expose our pick attributes. However, as we can't expect to
      # receive actual receptacles/studies/projects over the API, we convert them
      # from the ids. The RecordCache allows us to do this with a single database
      # query.

      ###
      # Custom Methods
      ###

      # Converts and sets pick attributes, ensuring the correct records are retrieved.
      #
      # @param picks [Array<Hash>] A list of pick attributes containing `source_receptacle_id`, `study_id`,
      #   and `project_id`.
      # @raise [JSONAPI::Exceptions::BadRequest] If a provided attribute does not match an actual record.
      def pick_attributes=(picks)
        # Extract and look up records here before passing through
        cache = PickList::RecordCache::ByReceptacle.new(picks)
        @model.pick_attributes = picks.map { |pick| cache.convert(pick.permit(PERMITTED_PICK_ATTRIBUTES)) }
      rescue KeyError => e
        # We'll see this if one of the attributes passed in doesn't match an actual record,
        # such as a non-existent study id.
        raise JSONAPI::Exceptions::BadRequest, e.message
      end

      # This provides an alternative API for passing in a list of labware, either by
      # ids or barcodes. This avoids the need to make additional requests for the receptacle
      # ids. We keep this as a separate accessor to avoid the confusion of passing in a list
      # of 12 picks, and receiving more back.
      #
      # @param labware_picks [Array<Hash>] A list of pick attributes containing `source_labware_barcode`,
      #   `study_id`, and `project_id`.
      # @raise [JSONAPI::Exceptions::BadRequest] If a provided attribute does not match an actual record.
      def labware_pick_attributes=(labware_picks)
        # Extract and look up records here before passing through
        cache = PickList::RecordCache::ByLabware.new(labware_picks)
        @model.pick_attributes =
          labware_picks.flat_map { |pick| cache.convert(pick.permit(PERMITTED_LABWARE_PICK_ATTRIBUTES)) }
      rescue KeyError => e
        # We'll see this if one of the attributes passed in doesn't match an actual record,
        # such as a non-existent study id.
        raise JSONAPI::Exceptions::BadRequest, e.message
      end

      # Retrieves the formatted pick attributes for API response.
      #
      # @return [Array<Hash>] A list of pick attributes containing `source_receptacle_id`, `study_id`, and `project_id`.
      def pick_attributes
        @model.pick_attributes.map do |pick|
          {
            source_receptacle_id: pick[:source_receptacle].id,
            study_id: pick[:study]&.id,
            project_id: pick[:project]&.id
          }
        end
      end
    end
  end
end
