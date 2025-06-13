# frozen_string_literal: true

# Provides behaviour for all labware resources
# While Plate/TubeResource doesn't strictly speaking inherit from
# LabwareResource there is an implied inheritance in the API interface. As a
# result it makes sense to ensure that all methods present on Labware are also
# on its effective subclasses (Liskov Substitution Principle) this is especially
# true for relationships, as it means we support pre-loading those relationships
# on mixed endpoints
module Api
  module V2
    module SharedBehaviour
      module Labware
        extend ActiveSupport::Concern

        included do
          # Associations:
          has_one :purpose, write_once: true, foreign_key: :plate_purpose_id, class_name: 'Purpose'
          has_one :custom_metadatum_collection, foreign_key_on: :related

          has_many :samples, write_once: true
          has_many :studies, write_once: true
          has_many :projects, write_once: true
          has_many :comments, readonly: true
          has_many :qc_files, readonly: true

          # If we are using api/v2/labware to pull back a list of labware, we may
          # expect a mix of plates and tubes. If we want to eager load their
          # contents we use the generic 'receptacles' association.
          has_many :receptacles, readonly: true, polymorphic: true
          has_many :ancestors, readonly: true, polymorphic: true
          has_many :descendants, readonly: true, polymorphic: true
          has_many :parents, readonly: true, polymorphic: true
          has_many :children, readonly: true, polymorphic: true
          has_many :child_plates, readonly: true
          has_many :child_tubes, readonly: true
          has_many :direct_submissions, readonly: true
          has_many :state_changes, readonly: true

          # Attributes
          attribute :uuid, readonly: true
          attribute :name, delegate: :display_name, readonly: true
          attribute :labware_barcode, readonly: true
          attribute :state, readonly: true
          attribute :created_at, readonly: true
          attribute :updated_at, readonly: true
          # Add retention_instruction as a readable attribute
          attribute :retention_instruction, delegate: :retention_instructions, readonly: true

          # Scopes
          filter :barcode, apply: ->(records, value, _options) { records.with_barcode(value) }
          filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
          filter :purpose_name,
                 apply:
                   (
                     lambda do |records, value, _options|
                       records.joins(:purpose).where(plate_purposes: { name: value })
                     end
                   )
          filter :purpose_id, apply: ->(records, value, _options) { records.where(plate_purpose_id: value) }
          filter :without_children, apply: ->(records, _value, _options) { records.without_children }
          filter :created_at_gt,
                 apply: lambda { |records, value, _options| records.where('labware.created_at > ?', value[0].to_date) }
          filter :updated_at_gt,
                 apply: lambda { |records, value, _options| records.where('labware.updated_at > ?', value[0].to_date) }
          filter :include_used, apply: ->(records, value, _options) { records.include_labware_with_children(value) }
          filter :state, apply: ->(records, value, _options) { records.in_state(value.flatten) }
        end

        # Custom methods
        # These shouldn't be used for business logic, and are more about
        # I/O and isolating implementation details.
        def labware_barcode
          {
            'ean13_barcode' => _model.ean13_barcode,
            'machine_barcode' => _model.machine_barcode,
            'human_barcode' => _model.human_barcode
          }
        end
      end
    end
  end
end
