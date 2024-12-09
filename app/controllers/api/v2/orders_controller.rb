# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for order
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class OrdersController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end

    class OrderProcessor < JSONAPI::Processor
      # Override the default behaviour for a JSONAPI::Processor when creating a new resource.
      # We need to check whether a template UUID was given, and, if so, use it to create the Order directly.
      # Where no template is given, the Order will be created via the base JSONAPI::Processor.
      def create_resource
        errors = []
        template = find_template { |new_errors| errors += new_errors }
        attributes = template_attributes { |new_errors| errors += new_errors } unless template.nil?

        return JSONAPI::ErrorsOperationResult.new(JSONAPI::BAD_REQUEST, errors) unless errors.empty?
        return super if template.nil? # No template means we should use the default behaviour.

        create_order_from_template(template, attributes)
      end

      private

      def find_template
        template_uuid = params[:data][:attributes][:submission_template_uuid]
        return nil if template_uuid.nil? # No errors -- we just don't have a template.

        template = SubmissionTemplate.with_uuid(template_uuid).first

        if template.nil?
          yield JSONAPI::Exceptions::InvalidFieldValue.new(:submission_template_uuid, template_uuid).errors
        end

        template
      end

      def template_attributes(&)
        parameters = params[:data][:attributes][:submission_template_attributes]

        if parameters.nil?
          yield JSONAPI::Exceptions::ParameterMissing.new(:submission_template_attributes).errors
          return
        end

        make_template_attributes(permitted_attributes(parameters), &)
      end

      def permitted_attributes(attributes)
        attributes.permit(
          { asset_uuids: [], request_options: {} },
          :autodetect_projects,
          :autodetect_studies,
          :user_uuid
        )
      end

      def make_template_attributes(attributes, &)
        {
          assets: extract_assets(attributes, &),
          autodetect_projects: attributes[:autodetect_projects],
          autodetect_studies: attributes[:autodetect_studies],
          request_options: require_attribute(attributes, :request_options, &),
          user: extract_user(attributes, &)
        }.compact
      end

      def extract_assets(attributes, &)
        asset_uuids = require_attribute(attributes, :asset_uuids, &)
        return nil if asset_uuids.nil?

        asset_uuids.map do |uuid|
          uuid_obj = Uuid.find_by(external_id: uuid)
          yield JSONAPI::Exceptions::InvalidFieldValue.new(:asset_uuids, uuid).errors if uuid_obj.nil?
          uuid_obj&.resource
        end
      end

      def extract_user(attributes, &)
        user_uuid = require_attribute(attributes, :user_uuid, &)
        return nil if user_uuid.nil?

        user = User.with_uuid(user_uuid).first
        yield JSONAPI::Exceptions::InvalidFieldValue.new(:user_uuid, user_uuid).errors if user.nil?
        user
      end

      def require_attribute(attributes, key)
        value = attributes.require(key)
        value = value.to_h if value.instance_of?(ActionController::Parameters) && value.permitted?
        value
      rescue ActionController::ParameterMissing
        yield JSONAPI::Exceptions::ParameterMissing.new("submission_template_attributes.#{key}").errors
        nil
      end

      def create_order_from_template(template, attributes)
        order = template.create_order!(attributes)
        resource = OrderResource.new(order, context)
        result = resource.replace_fields(params[:data])

        JSONAPI::ResourceOperationResult.new((result == :completed ? :created : :accepted), resource)
      end
    end
  end
end
