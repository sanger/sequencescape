# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {PrimerPanel}.
    #
    # A primer panel is a set of primers used in a genotyping by sequencing assay.
    # These primers bind to known regions of DNA, localised near SNPs (Single Nucleotide polymorphisms)
    # to allow them to be targeted by short read Sequencing.
    #
    # @note Access this resource via the `/api/v2/primer_panels/` endpoint.
    # @note This resource cannot be modified after creation: its endpoint will not accept `PATCH` requests.
    #
    # @example Fetching all primer panels
    #   GET /api/v2/primer_panels
    #
    # @example Fetching a primer panel by ID
    #   GET /api/v2/primer_panels/{id}
    #
    # @note the below example is currently broken, as `snp_count`` is a required attribute in the model
    # @example Creating a primer panel
    #   POST /api/v2/primer_panels
    #   {
    #     "data": {
    #       "type": "primer_panels",
    #       "attributes": {
    #         "name": "My Primer Panel",
    #         "programs": ["UAT"]
    #       }
    #     }
    #   }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class PrimerPanelResource < BaseResource
      ###
      # Attributes
      ###

      # @todo Add a `snp_count` attribute to the resource

      # @!attribute [rw] name
      #   The name of the primer panel.
      #   @return [String]
      attribute :name, write_once: true

      # @!attribute [rw] programs
      #   A list of programs associated with this primer panel.
      #   @return [Array<String>]
      attribute :programs, write_once: true
    end
  end
end
