# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of VolumeUpdate
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class VolumeUpdateResource < BaseResource
      model_name 'VolumeUpdate'

      # @!attribute created_by
      #  @return [String] the user who created the volume update.
      attribute :created_by

      # @!attribute asset_uuid
      #  @return [String] the uuid of the target labware associated with the volume update.
      attribute :target_uuid

      # @!attribute witnessed_by
      #  @return [Float] the volume change that occured on the target labware.
      attribute :volume_change

      # Sets the target Labware on the model using the UUID provided in the API create/update request.
      #
      # @param name [String] the uuid of the associated target Labware.
      # @return [void]
      def target_uuid=(uuid)
        @model.target = Uuid.with_external_id(uuid).include_resource.map(&:resource).first
      end

      # Transforms the target Labware into its UUID when generating an API query response.
      #
      # @return [String] the uuid of the associated target Labware.
      def target_uuid
        @model.target.uuid
      end

      # Gets the list of fields which are updatable on an existing VolumeUpdate.
      #
      # @param _context [JSONAPI::Resource::Context] not used.
      # @return [Array<Symbol>] the list of updatable fields.
      def self.updatable_fields(_context)
        []  # Do not allow updating any fields.
      end
    end
  end
end
