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
      # Get the Transfer model type needed to be created from the transfer template in the attributes.
      # Also put the transfers from the template into the attributes if they exist.
      def extract_template_data(attributes)
        errors = []

        template_uuid = attributes[:transfer_template_uuid]
        errors += JSONAPI::Exceptions::ParameterMissing.new('transfer_template_uuid').errors if template_uuid.nil?

        template = TransferTemplate.with_uuid(template_uuid).first
        errors +=
          JSONAPI::Exceptions::InvalidFieldValue.new('transfer_template_uuid', template_uuid).errors if template.nil?

        return nil, errors if errors.present?

        # Modify attributes according to what we've found in the template.
        attributes[:transfers] = template.transfers if template.transfers.present?

        [template.transfer_class_name.constantize, errors]
      end

      # Override the default behaviour for a JSONAPI::Processor when creating a new resource.
      # We need to parse for a transfer_template_uuid attribute so that it can be used to determine the polymorphic
      # type of the Transfer represented by a template. The create method is then passed the type to create.
      def create_resource
        data = params[:data]
        attributes = data[:attributes]
        model_type, errors = extract_template_data(attributes)

        return JSONAPI::ErrorsOperationResult.new(JSONAPI::BAD_REQUEST, errors) unless errors.empty?

        resource = TransferResource.create_with_model(context, model_type)
        result = resource.replace_fields(data)

        JSONAPI::ResourceOperationResult.new((result == :completed ? :created : :accepted), resource)
      end
    end
  end
end
