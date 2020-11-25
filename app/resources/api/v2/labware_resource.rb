# frozen_string_literal: true

module Api
  module V2
    # LabwareResource
    class LabwareResource < BaseResource
      attributes :uuid

      default_includes :uuid_object

      has_one :custom_metadatum_collection
      has_many :comments, readonly: true

      filter :purpose_name, apply: (lambda do |records, value, _options|
        records.joins(:purpose).where(plate_purposes: { name: value })
      end)
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
