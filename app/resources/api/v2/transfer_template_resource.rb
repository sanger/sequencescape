# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of a transfer template.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TransferTemplateResource < BaseResource
      immutable

      default_includes :uuid_object

      ###
      # Attributes
      ###

      # @!attribute [r]
      # @return [String] The name of the transfer template.
      attribute :name

      # @!attribute [r]
      # @return [String] The UUID of the transfer template.
      attribute :uuid, readonly: true
    end
  end
end
