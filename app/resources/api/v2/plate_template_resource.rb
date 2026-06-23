# frozen_string_literal: true

module Api
  module V2
    #
    # Provides a JSON:API representation of {PlateTemplate}.
    #
    # A `PlateTemplate` represents a virtual plate used in Cherrypicking to block out empty wells
    # or layout pre-assigned samples.

    # @note This resource is accessed via the `/api/v2/plate_templates/` endpoint.
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
      include Api::V2::SharedBehaviour::Labware

      model_name 'PlateTemplate'

      default_includes :uuid_object
    end
  end
end
