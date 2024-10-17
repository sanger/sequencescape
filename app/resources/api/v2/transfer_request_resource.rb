# frozen_string_literal: true

module Api
  module V2
    # @todo This documentation does not yet include a detailed description of what this resource represents.
    # @todo This documentation does not yet include detailed descriptions for relationships, attributes and filters.
    # @todo This documentation does not yet include any example usage of the API via cURL or similar.
    #
    # @note This resource is immutable: its endpoint will not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/transfer_requests/` endpoint.
    #
    # Provides a JSON:API representation of {TransferRequest}.
    #
    # For more information about JSON:API see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or look at the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation
    # of the JSON:API standard.
    class TransferRequestResource < BaseResource
      # Constants...

      immutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :target_asset, foreign_key: :target_asset_id, class_name: 'Receptacle'
      has_one :source_asset, relation_name: 'asset', foreign_key: :asset_id, class_name: 'Receptacle'
      has_one :submission, foreign_key: :submission_id, class_name: 'Submission'

      # Attributes
      attribute :uuid, readonly: true
      attribute :state, readonly: true
      attribute :volume, write_once: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
