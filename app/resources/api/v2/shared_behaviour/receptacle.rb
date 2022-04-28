# frozen_string_literal: true

# Provides behaviour for all receptacle resources
# While WellResource doesn't strictly speaking inherit from ReceptacleResource
# there is an implied inheritance in the API interface. As a result it makes
# sense to ensure that all methods present on Receptacle are also on Well
# (Liskov Substitution Principle) this is especially true for relationships,
# as it means we support pre-loading those relationships on mixed endpoints
module Api::V2::SharedBehaviour::Receptacle
  extend ActiveSupport::Concern

  included do
    ::Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }

    # Associations:
    has_many :samples, readonly: true
    has_many :studies, readonly: true
    has_many :projects, readonly: true

    has_many :requests_as_source, readonly: true, class_name: 'Request'
    has_many :requests_as_target, readonly: true, class_name: 'Request'
    has_many :qc_results, readonly: true
    has_many :aliquots, readonly: true

    has_many :downstream_assets, readonly: true, polymorphic: true, class_name: 'Receptacle'
    has_many :downstream_wells, readonly: true, class_name: 'Well'
    has_many :downstream_plates, readonly: true, class_name: 'Plate'
    has_many :downstream_tubes, readonly: true, class_name: 'Tube'

    has_many :upstream_assets, readonly: true, polymorphic: true, class_name: 'Receptacle'
    has_many :upstream_wells, readonly: true, class_name: 'Well'
    has_many :upstream_plates, readonly: true, class_name: 'Plate'
    has_many :upstream_tubes, readonly: true, class_name: 'Tube'

    has_many :transfer_requests_as_source, readonly: true, class_name: 'TransferRequest'
    has_many :transfer_requests_as_target, readonly: true, class_name: 'TransferRequest'

    # Attributes
    attribute :uuid, readonly: true
    attribute :name, delegate: :display_name, readonly: true
    attributes :pcr_cycles, :submit_for_sequencing, :sub_pool, :coverage, :diluent_volume
    attribute :state, readonly: true

    # Filters
    filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
  end
end
