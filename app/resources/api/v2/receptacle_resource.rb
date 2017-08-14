# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class ReceptacleResource < BaseResource
      # Constants...

      immutable # uncomment to make the resource immutable

      ::Tube.descendants.each do |subclass|
        model_hint model: subclass, resource: :tube
      end

      default_includes :uuid_object

      # Associations:
      has_many :samples
      has_many :studies
      has_many :projects

      # Attributes
      attribute :uuid, readonly: true
      attribute :name, delegate: :display_name, readonly: true

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
