# frozen_string_literal: true

module Api
  module V2
    # LabwareResource
    class LabwareResource < BaseResource
      attributes :uuid

      default_includes :uuid_object

      has_one :custom_metadatum_collection
      has_many :comments, readonly: true
      has_many :direct_submissions, readonly: true

      has_one :purpose, readonly: true, foreign_key: :plate_purpose_id

      has_many :ancestors, readonly: true, polymorphic: true
      has_many :descendants, readonly: true, polymorphic: true
      has_many :parents, readonly: true, polymorphic: true
      has_many :children, readonly: true, polymorphic: true

      filter :purpose_name,
             apply:
               (lambda { |records, value, _options| records.joins(:purpose).where(plate_purposes: { name: value }) })
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
