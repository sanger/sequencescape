# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Request::Metadata}.
    # which is a class derived from `app/models/metadata.rb`
    #
    # The RequestMetadataResource provides metadata information for requests,
    # specifically including details like `number_of_pools` and `cells_per_chip_well`,
    # which are critical for the scRNA Core pipeline. It is associated with a `request`.
    #
    # @note Access this resource via the `/api/v2/request_metadata/` endpoint.
    #
    # @example GET request to retrieve all request metadata
    #   GET /api/v2/request_metadata/
    #
    # @todo Figure out how to send a POST for a request with request metadata association. Currently,
    #   it is possible to create a request and request metadata seperately, but they are not associated
    #   with each other. How do you create the association, either in one request or after the
    #   individual requests?
    #
    # @example POST request to create new request metadata
    #   POST /api/v2/request_metadata/
    #   {
    #     "data": {
    #         "id": 1,
    #       "type": "request_metadata",
    #       "attributes": {
    #         // "number_of_pools": 5,
    #         // "cells_per_chip_well": 200
    #       },
    #       "relationships": {
    #         "request": {
    #           "data": {
    #             "type": "requests",
    #             "id": 1265
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # @example PATCH request to update existing request metadata
    #   PATCH /api/v2/request_metadata/1
    #   {
    #     "data": {
    #       "id": "1",
    #       "type": "request_metadata",
    #       "attributes": {
    #       }
    #     }
    #   }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class RequestMetadataResource < BaseResource
      # NB. request_metadata has been added to config/initializers/inflections.rb to make this class name
      # work otherwise it expects RequestMetadatumResource

      # Sets add_model_hint true by default, this allows updates from Limber, otherwise get a
      # 500 error as it looks for resource Api::V2::MetadatumResource
      model_name 'Request::Metadata'

      # Associations:
      has_one :request

      ###
      # Attributes
      ###

      # @!attribute [rw] number_of_pools
      #   @return [Int] the number_of_pools requested in the Submission. As used
      #     in the scRNA Core pipeline, it is specified at the Study-Project
      #     level: it will have the same value for all Requests that share the
      #     same Study and Project. It is used in the pooling algorithm.
      attribute :number_of_pools, write_once: true

      # @!attribute [rw] cells_per_chip_well
      #   @return [Int] the cells_per_chip_well requested in the Submission. As
      #     used in the scRNA Core pipeline, it is specified at the Study-Project
      #     level: it will have the same value for all Requests that share the
      #     same Study and Project. It is used for volume calculations for
      #     pooling.
      attribute :cells_per_chip_well, write_once: true

      # @!attribute [r] allowance_band
      #   @return [String] the allowance_band requested in the Submission. As
      #     used in the scRNA Core pipeline, it is specified at the Study-Project
      #     level: it will have the same value for all Requests that share the
      #     same Study and Project.
      attribute :allowance_band, read_only: true
    end
  end
end
