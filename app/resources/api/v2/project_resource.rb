# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON:API representation of {Project}.
    #
    # A Project represents a defined research or sequencing initiative within the system. It holds the cost
    #   code, for billing.
    #
    # @note This resource is **immutable**: it does not accept `POST`, `PATCH`, or `DELETE` requests.
    # @note Access this resource via the `/api/v2/projects/` endpoint.
    #
    # @example Fetching all projects
    #   GET /api/v2/projects
    #
    # @example Fetching a project by ID
    #   GET /api/v2/projects/{id}
    #
    # For more details on JSON:API, see the [JSON:API Specifications](https://jsonapi.org/format/)
    # or check out the [JSONAPI::Resources](http://jsonapi-resources.com/) package for Sequencescape's implementation.
    class ProjectResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [rw] name
      #   The name of the project.
      #   @return [String]
      attribute :name

      # @!attribute [rw] cost_code
      #   The financial cost code associated with the project.
      #   This is delegated to `project_cost_code` in the underlying model.
      #   @return [String]
      attribute :cost_code, delegate: :project_cost_code

      # @!attribute [r] uuid
      #   @note This identifier is automatically assigned upon creation and cannot be modified.
      #   @return [String] The universally unique identifier (UUID) of project.
      attribute :uuid, readonly: true

      ###
      # Filters
      ###

      # @!method filter_by_name
      #   Allows filtering projects by name.
      #   @example Fetching projects by name
      #     GET /api/v2/projects?filter[name]=Example
      filter :name
    end
  end
end
