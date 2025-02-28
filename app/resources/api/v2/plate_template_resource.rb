# frozen_string_literal: true

module Api
  module V2
    # @todo Is this resource required? It fails when fetching any plate templates.
    # Provides a JSON:API representation of {PlateTemplate}.
    #
    # A `PlateTemplate` represents a virtual plate used in Cherrypicking and GateKeeper to block out empty wells
    # or layout pre-assigned samples.

    # @note This resource is accessed via the `/api/v2/plate_templates/` endpoint.
    #
    # @note The below GET examples are current throwing an exception, but are included here for reference.
    #
    # @example GET request to retrieve all plate templates
    #   GET /api/v2/plate_templates/
    #
    # @example GET request to retrieve a specific plate template by ID
    #   GET /api/v2/plate_templates/123/
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class PlateTemplateResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The UUID of the plate template.
      attribute :uuid, readonly: true
    end
  end
end
