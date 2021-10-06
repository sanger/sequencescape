# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of Tube
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TubeResource < BaseResource
      # Constants...

      immutable # comment to make the resource mutable

      default_includes :uuid_object, :barcodes, :transfer_requests_as_target

      # Associations:
      has_one :purpose, readonly: true, foreign_key: :plate_purpose_id, class_name: 'Purpose'
      has_one :custom_metadatum_collection

      has_many :samples, readonly: true
      has_many :studies, readonly: true
      has_many :projects, readonly: true
      has_many :aliquots, readonly: true
      has_many :direct_submissions, readonly: true

      has_many :ancestors, readonly: true, polymorphic: true
      has_many :descendants, readonly: true, polymorphic: true
      has_many :parents, readonly: true, polymorphic: true
      has_many :children, readonly: true, polymorphic: true

      has_many :child_plates, readonly: true
      has_many :child_tubes, readonly: true

      has_many :comments, readonly: true
      has_many :state_changes, readonly: true

      has_one :receptacle, readonly: true, foreign_key_on: :related

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attribute :labware_barcode, readonly: true
      attribute :state, readonly: true
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true

      # Filters
      filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
      filter :purpose_name,
             apply:
               (
                 lambda do |records, value, _options|
                   purpose = Purpose.where(name: value)
                   records.where(plate_purpose_id: purpose)
                 end
               )
      filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
      filter :include_used, apply: ->(records, value, _options) { records.include_labware_with_children(value) }

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.
      def labware_barcode
        {
          'ean13_barcode' => _model.ean13_barcode,
          'machine_barcode' => _model.machine_barcode,
          'human_barcode' => _model.human_barcode
        }
      end

      # Class method overrides
    end
  end
end
