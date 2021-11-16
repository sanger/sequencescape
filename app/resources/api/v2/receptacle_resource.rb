# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class ReceptacleResource < BaseResource
      # immutable # uncomment to make the resource immutable

      default_includes :uuid_object

      ::Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }

      # Associations:
      has_many :samples
      has_many :studies
      has_many :projects

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

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true
      attributes :pcr_cycles, :submit_for_sequencing, :sub_pool, :coverage, :diluent_volume

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
