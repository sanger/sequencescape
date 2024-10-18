# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Transfers.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
    class TransfersController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most of the standard behaviour.
      # However in this case we want to redirect create and update operations to the correct polymorphic type.

      def process_operations(operations)
        # We need to determine the polymorphic type of the transfer to create based on any template provided.
        operations.each do |operation|
          # Neither data nor attributes are guaranteed among the operation options.
          attributes = operation.options.fetch(:data, {}).fetch(:attributes, {})

          # Skip the operation if it does not contain a transfer template.
          next unless attributes.key?(:transfer_template_uuid)

          # Get the transfer template and use it to update the context and attributes.
          template = TransferTemplate.with_uuid(attributes[:transfer_template_uuid]).first
          operation.options[:context][:polymorphic_type] = template.transfer_class_name
          attributes[:transfers] = template.transfers if template.transfers.present?

          # Remove the UUID of the transfer template from the attributes.
          attributes.delete(:transfer_template_uuid)
        end

        super(operations)
      end
    end
  end
end
