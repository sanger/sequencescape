# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcAssay}.
    #
    # A QC Assay groups together a set of QC Results which were performed
    # together. It allows for attributes which are associated with each other
    # such as loci_passed and loci_tested to be coupled
    #
    # @note Access this resource via the `/api/v2/qc_assays/` endpoint.
    # @note At the time of writing, I was unable to create a valid PATCH request for this resource.
    #
    # @example GET request to retrieve all QC assays
    #   GET /api/v2/qc_assays/
    #
    # @todo the below `qc_results` attribute is an array of `QcResultResource` objects.
    #   It returns a `201 Created` even when no record is created (when no `qc_result` objects are passed).
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    #
    # @todo the below `qc_results` relationship is include for reference only. It appears to be
    #   redundant. See `qc_results` relationship comment.
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    #
    # @example POST request to create a new QC assay, with a an Asset `barcode` provded in the `qc_results` attribute
    #   POST /api/v2/qc_assays/
    #   {
    #     "data": {
    #       "type": "qc_assay",
    #       "attributes": {
    #         "lot_number": "67890",
    #         "qc_results": [
    #           {
    #             // "id": 45
    #             "uuid": "9dd79a6c-f524-11ef-8842-000000000000",
    #             "key": "x",
    #             "value": "x",
    #             "units": "s"
    #           }
    #         ]
    #       },
    #       "relationships": {
    #         "qc_results": {
    #           "data": {
    #             "type": "qc_results",
    #             "id": 45
    #           }
    #         }
    #       }
    #     }
    #   }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class QcAssayResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] lot_number
      #   The lot number associated with the QC assay.
      #   @return String
      attribute :lot_number

      # @!attribute [rw] qc_results
      #   The results of the QC assay. This is an array of QC Results associated with the assay.
      #   It also includes attributes to associated the QcResult with the Asset.
      #   This is provided by either a `uuid` or `barcode` attribute.
      #   When both are provided, the `uuid` attribute will be used to associate the {QcResult} with the asset.
      #   @return [Array<QcResultResource>]
      attribute :qc_results

      ###
      # Relationships
      ###

      # @!attribute [r] qc_results
      #   The Qc Results associated with the QC assay.
      #   @note This relationship appears to be redundant. A new Qc Result record is created with
      #     every request, by providing the `qc_results` attribute in the request.
      #   @todo deprecate, fix, or update this relationship to be read-only
      #   @return [Array<QcResultResource>]
      has_many :qc_results
    end
  end
end
