# frozen_string_literal: true

module Api
  module V2
    # AssetResource
    class AssetResource < JSONAPI::Resource
      attributes :uuid

      filter :purpose_name, apply: (lambda do |records, value, _options|
        records.joins('LEFT JOIN plate_purposes ON plate_purposes.id = assets.plate_purpose_id').where(plate_purposes: { name: value })
      end)
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
    end
  end
end
