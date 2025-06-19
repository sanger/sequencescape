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
      before_create_resource :prepare_context

      private

      def prepare_context
        context[:template] = find_template
        context[:template_attributes] = template_attributes unless context[:template].nil?
      end

      def find_template
        template_uuid = params[:data][:attributes][:submission_template_uuid]
        return nil if template_uuid.nil? # No errors -- we just don't have a template.

        template = SubmissionTemplate.with_uuid(template_uuid).first
        raise JSONAPI::Exceptions::InvalidFieldValue.new(:submission_template_uuid, template_uuid) if template.nil?

        template
      end

      def template_attributes
        parameters = params[:data][:attributes][:submission_template_attributes]

        raise JSONAPI::Exceptions::ParameterMissing, :submission_template_attributes if parameters.nil?

        make_template_attributes(permitted_attributes(parameters))
      end

      def permitted_attributes(attributes)
        attributes.permit(
          { asset_uuids: [], request_options: {} },
          :autodetect_projects,
          :autodetect_studies,
          :user_uuid
        )
      end

      def make_template_attributes(attributes)
        {
          assets: extract_assets(attributes),
          autodetect_projects: attributes[:autodetect_projects],
          autodetect_studies: attributes[:autodetect_studies],
          request_options: require_attribute(attributes, :request_options),
          user: extract_user(attributes)
        }.compact
      end

      def extract_assets(attributes)
        asset_uuids = require_attribute(attributes, :asset_uuids)
        return nil if asset_uuids.nil?

        asset_uuids.map do |uuid|
          uuid_obj = Uuid.find_by(external_id: uuid)
          raise JSONAPI::Exceptions::InvalidFieldValue.new(:asset_uuids, uuid) if uuid_obj.nil?

          uuid_obj&.resource
        end
      end

      def extract_user(attributes)
        user_uuid = require_attribute(attributes, :user_uuid)
        return nil if user_uuid.nil?

        user = User.with_uuid(user_uuid).first
        raise JSONAPI::Exceptions::InvalidFieldValue.new(:user_uuid, user_uuid) if user.nil?

        user
      end

      def require_attribute(attributes, key)
        value = attributes.require(key)
        value = value.to_h if value.instance_of?(ActionController::Parameters) && value.permitted?
        value
      rescue ActionController::ParameterMissing
        raise JSONAPI::Exceptions::ParameterMissing, "submission_template_attributes.#{key}"
      end
    end
  end
end
