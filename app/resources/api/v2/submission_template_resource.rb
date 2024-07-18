# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a submission template.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class SubmissionTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r]
      # @return [String] The name of the submission template.
      attribute :name

      # @!attribute [r]
      # @return [String] The UUID of the submission template.
      attribute :uuid
    end
  end
end
