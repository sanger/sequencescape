# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {UltimaApplication}.
    #
    # An Ultima application (e.g. "10x Flex") is selected when submitting an Illumina to Ultima
    # library conversion. It is stored by name in the request options (`ultima_application`), and
    # links to the UGA and UGB primers that the lab needs to use when preparing samples.
    #
    # @note Access this resource via the `/api/v2/ultima_applications/` endpoint.
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    #
    # @example GET request for all Ultima applications
    #   GET /api/v2/ultima_applications/
    #
    # @example GET request for a specific Ultima application by ID, including its primers
    #   GET /api/v2/ultima_applications/1?include=uga_primer,ugb_primer
    #
    # @example Filtering by name (as stored in the request options)
    #   GET /api/v2/ultima_applications?filter[name]=10x Flex&include=uga_primer,ugb_primer
    #
    # For more information about JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class UltimaApplicationResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] name
      #   The name of the application, as used in the UI and bulk submissions, e.g. "10x Flex".
      #   @return [String]
      attribute :name, readonly: true

      # @!attribute [r] description
      #   The description of the application, e.g. "10x Genomics GEM-X Flex Gene Expression".
      #   @return [String]
      attribute :description, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] uga_primer
      #   The UGA indexing primer (Forward/R1 side) used for this application.
      #   @return [Api::V2::UltimaPrimerResource]
      has_one :uga_primer, readonly: true, class_name: 'UltimaPrimer'

      # @!attribute [r] ugb_primer
      #   The UGB primer (Reverse/R2 side) used for this application.
      #   @return [Api::V2::UltimaPrimerResource]
      has_one :ugb_primer, readonly: true, class_name: 'UltimaPrimer'

      ###
      # Filters
      ###

      # @!method name
      #   A filter to return only Ultima applications with the given name(s).
      #   @example
      #     GET /api/v2/ultima_applications?filter[name]=10x Flex
      filter :name, apply: ->(records, value, _options) { records.with_name(value) }
    end
  end
end
