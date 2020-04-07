# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of TransferRequest
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TransferRequestResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      # model_name / model_hint if required

      default_includes :uuid_object

      # Associations:
      has_one :target_asset, foreign_key: :target_asset_id, class_name: 'Receptacle'
      has_one :source_asset, relation_name: 'asset', foreign_key: :asset_id, class_name: 'Receptacle'
      has_one :submission, foreign_key: :submission_id, class_name: 'Submission'

      # Attributes
      attribute :uuid, readonly: true
      attribute :state, readonly: true
      attribute :volume, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
