# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {SampleManifest} for managing sample manifests.
    #
    # A sample manifest resource represents a collection of samples, typically associated with a specific experiment or project.
    # This resource allows clients to retrieve information about the sample manifest and its attributes.
    #

    # A {SampleManifest} is the primary way new {Sample samples} enter Sequencescape.
    # It registers labware, reserves {SangerSampleId Sanger sample ids}, and generates
    # a {SampleManifestExcel} spreadsheet for the customer.
    #
    # The generated labware is determined by the {#asset_type}, which switches out
    # the {#core_behaviour} module {SampleManifest::CoreBehaviour}. This handles
    # generating {Labware}, {Receptacle receptacles}, and setting manifest-specific
    # properties on {Aliquot}.
    #
    # All {Sample samples} in a manifest initially belong to a single {Study}, but
    # can be associated with additional studies over time.

    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/sample_manifests/` endpoint.
    #
    # @example GET request for all SampleManifest resources
    #   GET /api/v2/sample_manifests/
    #
    # @example GET request for a SampleManifest with ID 123
    #   GET /api/v2/sample_manifests/123/
    #
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class SampleManifestResource < BaseResource
      immutable

      ###
      # Attributes
      ###

      # @!attribute [r] supplier_name
      #   The name of the supplier providing the sample manifest.
      #   @return [String] The name of the supplier.
      #   @note This field is readonly as this resource is immutable.
      attribute :supplier_name
    end
  end
end
