# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {QcResult}.
    #
    # A {QcResult} represents a single quality control measurement, qualitative or quantitative
    # about an {Asset}.
    #
    # It includes {QcResult} attributes such as the key, value, units, coefficient of variation (CV),
    # assay type, and assay version.
    #
    # It also includes attributes to associated the QcResult with the Asset.
    # This is provided by either a `uuid` or `barcode` attribute.
    # When both are provided, the `uuid` attribute will be used to associate the {QcResult} with the asset.
    #
    # @note Access this resource via the `/api/v2/qc_results/` endpoint.
    #
    # @example GET request to retrieve all QC results
    #   GET /api/v2/qc_results/
    #
    # @todo the below `asset` relationship is include for reference only. It appears to be
    #  redundant. Instead, an Asset `barcode` or `uuid` attribute must be provided in the request.
    #  See `asset` relationship comment.
    #  Additionally, other attributes are allowed in the request both, and it does not throw and error
    #   See [Y25-236](https://github.com/sanger/sequencescape/issues/4812).
    #
    # @example POST request to create a new QC result, with Asset `uuid`
    #   POST /api/v2/qc_results/
    #   {
    #     "data": {
    #       "type": "qc_result",
    #       "attributes": [{
    #         "uuid":"9c4c2fe0-7cdf-11ef-b4cc-000000000000",
    #         // "barcode": "NT3Q",
    #         "key": "measurement_key",
    #         "value": "12.5555",
    #         "units": "ng/µL",
    #         "cv": "5.5",
    #         "assay_type": "PCR",
    #         "assay_version": "v1.0"
    #       }],
    #       "relationships": {
    #       "asset": {
    #         "data": {
    #           "type": "asset",
    #           "id": "3000"
    #         }
    #       }
    #       }
    #     }
    #   }

    # @example POST request to create a new QC result, with Asset `barcode`
    #   POST /api/v2/qc_results/
    #   {
    #     "data": {
    #       "type": "qc_result",
    #       "attributes": [{
    #         "barcode": "NT3Q",
    #         "key": "measurement_key",
    #         "value": "12.5",
    #         "units": "ng/µL",
    #         "cv": "5.5",
    #         "assay_type": "PCR",
    #         "assay_version": "v1.0"
    #       }]
    #     }
    #   }

    # @example PATCH request to update an existing QC result
    #   PATCH /api/v2/qc_results/20
    #   {
    #     "data": {
    #       "id": 20,
    #       "type": "qc_results",
    #       "attributes": {
    #         "key": "measurement_key",
    #         "value": "12.3",
    #         "units": "ng/µL",
    #         "cv": "5.5",
    #         "assay_type": "PCR",
    #         "assay_version": "v1.0"
    #       }
    #     }
    #   }
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class QcResultResource < BaseResource
      ###
      # Attributes
      ###

      # @!attribute [rw] key
      #   The attribute being measured. Eg. Concentration
      #   @note This is a required attribute.
      #   @return [String]
      attribute :key

      # @!attribute [rw] value
      #   The measured value of the QC result recorded
      #   @note This is a required attribute.
      #   @return [String, Numeric]
      attribute :value

      # @!attribute [rw] units
      #   The units in which the measurement was recorded (e.g., "ng/µL").
      #   @note This is a required attribute.
      #   @return [String]
      attribute :units

      # @!attribute [rw] cv
      #   The coefficient of variation for the QC result (e.g., "5.5").
      #   @return [String, Numeric]
      attribute :cv

      # @!attribute [rw] assay_type
      #   The type of assay used for the QC result (e.g., "PCR").
      #   @return [String]
      attribute :assay_type

      # @!attribute [rw] assay_version
      #   The version of the assay used for the QC result (e.g., "v1.0").
      #   @return [String]
      attribute :assay_version

      # @!attribute [r] created_at
      #   The timestamp indicating when this metadata entry was created.
      #   @return [DateTime] The creation time of the metadata record.
      attribute :created_at, readonly: true

      ###
      # Relationships
      ###

      # @!attribute [r] asset
      #   The Asset associated with the QC result.
      #   @note This relationship appears to be redundant. Instead, an Asset `barcode` or `uuid` attribute
      #     must be provided in the request, which will be used to associate the QC result with the asset.
      #   @todo deprecate, fix, or update this relationship to be read-only
      #   @return [AssetResource]
      has_one :asset
    end
  end
end
