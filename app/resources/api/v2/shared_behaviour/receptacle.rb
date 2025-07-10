# frozen_string_literal: true

# Provides behaviour for all receptacle resources
# While WellResource doesn't strictly speaking inherit from ReceptacleResource
# there is an implied inheritance in the API interface. As a result it makes
# sense to ensure that all methods present on Receptacle are also on Well
# (Liskov Substitution Principle) this is especially true for relationships,
# as it means we support pre-loading those relationships on mixed endpoints
module Api
  module V2
    module SharedBehaviour
      module Receptacle
        extend ActiveSupport::Concern

        included do
          # Associations:
          has_many :samples, readonly: true
          has_many :studies, write_once: true
          has_many :projects, write_once: true

          has_many :requests_as_source, readonly: true
          has_many :requests_as_target, readonly: true
          has_many :qc_results, readonly: true
          has_many :aliquots, readonly: true

          has_many :downstream_assets, readonly: true, polymorphic: true
          has_many :downstream_wells, readonly: true
          has_many :downstream_plates, readonly: true
          has_many :downstream_tubes, readonly: true

          has_many :upstream_assets, readonly: true, polymorphic: true
          has_many :upstream_wells, readonly: true
          has_many :upstream_plates, readonly: true
          has_many :upstream_tubes, readonly: true

          has_many :transfer_requests_as_source, readonly: true
          has_many :transfer_requests_as_target, readonly: true

          has_one :labware, write_once: true

          # Attributes
          attribute :uuid, readonly: true
          attribute :name, delegate: :display_name, write_once: true
          attributes :pcr_cycles, :submit_for_sequencing, :sub_pool, :coverage, :diluent_volume, :diluent_molarity
          attribute :state, readonly: true

          # Filters
          filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
        end
      end
    end
  end
end
