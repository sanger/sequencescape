# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a receptacle
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class ReceptacleResource < BaseResource
      # We import most receptacle shared behaviour, this includes associations,
      # attributes and filters. By adding behaviour here we ensure that it
      # is automatically available on well.
      include Api::V2::SharedBehaviour::Receptacle

      # immutable # uncomment to make the resource immutable

      default_includes :uuid_object

      # Associations:

      # Attributes

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # Class method overrides
    end
  end
end
