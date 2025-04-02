# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {VolumeUpdate} for the tracking of volume changes associated with labware.
    #
    # Performs a change of volume on a resource
    # Primarily created on plates via Assets Audits application to indicate reduced
    # volume on, eg. working dilution creation.
    # No records exist on 29/05/2019 due to no volumes configured for processes
    #
    # @note Access this resource via the `/api/v2/volume_updates/` endpoint.
    # @note Updates are not allowed on this resource @see self.updatable_fields
    #
    # @example POST request to create a volume update
    #   POST /api/v2/volume_updates/
    #   {
    #     "data": {
    #       "type": "volume_updates",
    #       "attributes": {
    #         "created_by": "me",
    #         "target_uuid": "9dc5f262-f524-11ef-8842-000000000000",
    #         "volume_change": -2.345
    #       }
    #     }
    #   }
    #
    # @example GET request for all VolumeUpdate resources
    #   GET /api/v2/volume_updates/
    #
    # @example GET request for a specific VolumeUpdate resource with ID 123
    #   GET /api/v2/volume_updates/123/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class VolumeUpdateResource < BaseResource
      model_name 'VolumeUpdate'

      ###
      # Attributes
      ###

      # @!attribute [rw] created_by
      #   The user who created the volume update.
      #   @todo This can be any string, update to use a `user` relationship
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      #   @return [String] the UUID of the user who created the volume update.
      #   @note This attribute is required.
      attribute :created_by

      # @!attribute [rw] target_uuid
      #   The UUID of the target labware associated with the volume update.
      #   @return [String] the UUID of the labware whose volume has been updated.
      #   @note This attribute is required.
      attribute :target_uuid

      # @!attribute [rw] volume_change
      #   The amount of volume change that occurred on the target labware.
      #   @return [Float] the volume change value (e.g., 5.0 for an increase of 5 units).
      #   @note This attribute is required.
      attribute :volume_change

      ###
      # Attribute methods
      ###

      # Sets the target Labware on the model using the UUID provided in the API create/update request.
      # @todo Deprecate this method in favour of using the `target` relationship.
      #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      # @param uuid [String] the UUID of the associated target labware.
      # @return [void]
      def target_uuid=(uuid)
        @model.target = Uuid.with_external_id(uuid).include_resource.map(&:resource).first
      end

      # Transforms the target Labware into its UUID when generating an API query response.
      #
      # @return [String] the UUID of the associated target labware.
      def target_uuid
        @model.target.uuid
      end

      ###
      # Callbacks
      ###

      # Gets the list of fields which are updatable on an existing VolumeUpdate.
      # @todo Use `except: %i[update]` in `routes.rb` or the access restrictions instead of this approach
      #     See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
      # @param _context [JSONAPI::Resource::Context] not used.
      # @return [Array<Symbol>] the list of updatable fields (empty in this case as updates are not allowed).
      def self.updatable_fields(_context)
        [] # Do not allow updating any fields.
      end
    end
  end
end
