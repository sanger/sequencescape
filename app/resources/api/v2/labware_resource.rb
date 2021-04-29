# frozen_string_literal: true

module Api
  module V2
    # LabwareResource
    class LabwareResource < BaseResource
      attributes :uuid

      default_includes :uuid_object, :barcodes

      has_one :purpose, readonly: true, foreign_key: :plate_purpose_id
      has_one :custom_metadatum_collection
      has_many :comments, readonly: true
      has_many :direct_submissions, readonly: true
      has_many :state_changes, readonly: true

      filter :purpose_name, apply: (lambda do |records, value, _options|
        records.joins(:purpose).where(plate_purposes: { name: value })
      end)
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :without_children, apply: ->(records, _value, _options) { records.without_children }
    end
  end
end
