# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Lane}, representing sequencing lanes within a flowcell.
    #
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/lanes/` endpoint.
    #
    # @example GET request for all Lane resources
    #   GET /api/v2/lanes/
    #
    # @example GET request for a single Lane resource with ID 123
    #   GET /api/v2/lanes/123/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out [JSONAPI::Resources](http://jsonapi-resources.com/) for Sequencescape's implementation.
    class LaneResource < BaseResource
      immutable

      ###
      # Relationships
      ###

      # @!attribute [r] samples
      #   The samples associated with this lane.
      #   @return [Array<SampleResource>] A list of samples present in this lane.
      has_many :samples

      # @!attribute [r] studies
      #   The studies associated with this lane.
      #   @return [Array<StudyResource>] A list of studies linked to this lane.
      has_many :studies

      # @!attribute [r] projects
      #   The projects associated with this lane.
      #   @return [Array<ProjectResource>] A list of projects related to this lane.
      has_many :projects

      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The unique identifier for the lane.
      attribute :uuid, readonly: true

      # @!attribute [r] name
      #   The display name of the lane.
      #   @return [String] The human-readable name of the lane.
      attribute :name, delegate: :display_name

      # attribute :position
      # attribute :labware_barcode

      ###
      # Filters
      ###

      ###
      # Custom Methods
      ###

      # Returns a hash containing the barcodes associated with the labware in this lane.
      # @return [Hash] A hash with keys for barcode types and their corresponding values.
      # def labware_barcode
      #   {
      #     ean13_barcode: _model.labware.ean13_barcode,
      #     human_barcode: _model.labware.human_barcode
      #   }
      # end
    end
  end
end
