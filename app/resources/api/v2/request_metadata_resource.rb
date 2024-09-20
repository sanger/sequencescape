# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note Access this resource via the `/api/v2/requests_metadata/` endpoint.
    #
    # Provides a JSON:API representation of {Request::Metadata}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class RequestMetadataResource < BaseResource
      # NB. request_metadata has been added to config/initializers/inflections.rb to make this class name work otherwise it
      # expects RequestMetadatumResource

      # Sets add_model_hint true by default, this allows updates from Limber, otherwise get a
      # 500 error as it looks for resource Api::V2::MetadatumResource
      model_name 'Request::Metadata'

      # Associations:
      has_one :request

      ###
      # Attributes
      ###

      # @!attribute [r] number_of_samples_per_pool
      #   @return [Int] the number_of_samples_per_pool.
      attribute :number_of_samples_per_pool, readonly: true

      # @!attribute [r] cells_per_chip_well
      #   @return [Int] the cells_per_chip_well.
      attribute :cells_per_chip_well, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
