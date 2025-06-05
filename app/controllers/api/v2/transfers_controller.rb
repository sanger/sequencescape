# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Transfers.
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation.
    class TransfersController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most of the standard behaviour.
      # However in this case we want to redirect create and update operations to the correct polymorphic type.
    end

    class TransferProcessor < JSONAPI::Processor
      before_create_resource :extract_template_data

      private

      # Put the Transfer model_type needed to be created from the transfer template in the context.
      # Also put the transfers from the template into the attributes if they exist.
      def extract_template_data
        attributes = params[:data][:attributes]
        template_uuid = attributes[:transfer_template_uuid]
        raise JSONAPI::Exceptions::ParameterMissing, 'transfer_template_uuid' if template_uuid.nil?

        template = TransferTemplate.with_uuid(template_uuid).first
        raise JSONAPI::Exceptions::InvalidFieldValue.new('transfer_template_uuid', template_uuid) if template.nil?

        # Modify attributes according to what we've found in the template.
        attributes[:transfers] = template.transfers if template.transfers.present?
        context[:model_type] = template.transfer_class_name.constantize
      end
    end
  end
end
