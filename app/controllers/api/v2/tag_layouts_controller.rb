# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for Tag Layouts
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class TagLayoutsController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
    end

    class TagLayoutProcessor < JSONAPI::Processor
      def find_template
        errors = []

        template_uuid = params[:data][:attributes][:tag_layout_template_uuid]
        return nil, errors if template_uuid.nil? # No errors -- we just don't have a template.

        template = TagLayoutTemplate.with_uuid(template_uuid).first
        errors +=
          JSONAPI::Exceptions::InvalidFieldValue.new(:tag_layout_template_uuid, template_uuid).errors if template.nil?

        [template, errors]
      end

      def error_if_key_present(data, key)
        return [] if data[key.to_sym].blank?

        JSONAPI::Exceptions::BadRequest.new(
          "Cannot provide '#{key}' while also providing 'tag_layout_template_uuid'."
        ).errors
      end

      def merge_template_attributes(template)
        errors = []

        data = params[:data]

        %i[walking_by direction].each do |attr_key|
          next if template.send(attr_key).blank?

          errors += error_if_key_present(data[:attributes], attr_key)

          data[:attributes][attr_key] = template.send(attr_key)
        end

        errors
      end

      def merge_template_to_one_relationships(template)
        errors = []

        data = params[:data]

        %i[tag_group tag2_group].each do |rel_key|
          next if template.send(rel_key).blank?

          errors += error_if_key_present(data[:attributes], "#{rel_key}_uuid")
          errors += error_if_key_present(data[:to_one], rel_key)

          data[:to_one][rel_key] = template.send(rel_key).id
        end

        errors
      end

      def merge_template_data(template)
        merge_template_attributes(template) + merge_template_to_one_relationships(template)
      end

      # Override the default behaviour for a JSONAPI::Processor when creating a new resource.
      # We need to check whether a template UUID was given, and, if so, copy its data into this
      # new TagLayoutResource. The creation will be prevented if any data from the template is also
      # included in the create request as additional values. e.g. a request has a template UUID and
      # also specifies a direction or a tag_group. In this case, the error will indicate that the
      # template UUID was not an allowed attribute.
      def create_resource
        template, errors = find_template
        errors += merge_template_data(template) unless template.nil?

        return JSONAPI::ErrorsOperationResult.new(400, errors) unless errors.empty?

        # Perform the usual create actions.
        resource = TagLayoutResource.create(context)
        result = resource.replace_fields(params[:data])

        JSONAPI::ResourceOperationResult.new((result == :completed ? :created : :accepted), resource)
      end
    end
  end
end
