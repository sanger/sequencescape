# frozen_string_literal: true

module Api
  module V2
    # AssetResource
    class AssetResource < BaseResource
      attributes :uuid

      default_includes :uuid_object

      has_one :custom_metadatum_collection
      has_many :comments, readonly: true

      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   records.joins('LEFT JOIN plate_purposes ON plate_purposes.id = assets.plate_purpose_id').where(
                     plate_purposes: {
                       name: value
                     }
                   )
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
    end
  end
end
