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

      # @!method filter_uuid
      #   Filter the transfer templates by UUID.
      #   @example URL with UUID filter
      #     https://sequencescape.psd.sanger.ac.uk/api/v2/transfer_templates?filter[uuid]=12345678-1234-1234-1234-123456789012
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }
    end
  end
end
