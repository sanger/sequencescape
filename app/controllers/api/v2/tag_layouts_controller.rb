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
      around_create_resource :apply_template

      private

      # We need to check whether a template UUID was given, and, if so, copy its data into this
      # new TagLayoutResource. The creation will be prevented if any data from the template is also
      # included in the create request as additional values. e.g. a request has a template UUID and
      # also specifies a direction or a tag_group. In this case, the error will indicate that the
      # template UUID was not an allowed attribute.
      def apply_template
        template = merge_template_data
        yield
        record_template_use(template) unless template.nil?
      end

      def find_template
        template_uuid = params[:data][:attributes][:tag_layout_template_uuid]
        return nil if template_uuid.nil? # No errors -- we just don't have a template.

        template = TagLayoutTemplate.with_uuid(template_uuid).first

        raise JSONAPI::Exceptions::InvalidFieldValue.new(:tag_layout_template_uuid, template_uuid) if template.nil?

        template
      end

      def raise_if_key_present(data, key)
        return if data[key.to_sym].blank?

        raise JSONAPI::Exceptions::BadRequest,
              "Cannot provide '#{key}' while also providing 'tag_layout_template_uuid'."
      end

      def merge_template_attributes(template)
        data = params[:data]

        %i[walking_by direction].each do |attr_key|
          next if template.send(attr_key).blank?

          raise_if_key_present(data[:attributes], attr_key)

          data[:attributes][attr_key] = template.send(attr_key)
        end
      end

      def merge_template_to_one_relationships(template)
        data = params[:data]

        %i[tag_group tag2_group].each do |rel_key|
          next if template.send(rel_key).blank?

          raise_if_key_present(data[:attributes], "#{rel_key}_uuid")
          raise_if_key_present(data[:to_one], rel_key)

          data[:to_one][rel_key] = template.send(rel_key).id
        end
      end

      def merge_template_data
        template = find_template

        unless template.nil?
          merge_template_attributes(template)
          merge_template_to_one_relationships(template)
        end

        template
      end

      def enforce_uniqueness?
        data = params[:data]
        attributes = data[:attributes]
        tag2_group_present = attributes[:tag2_group_uuid].present? || data[:to_one][:tag2_group].present?

        attributes.fetch(:enforce_uniqueness, tag2_group_present)
      end

      def record_template_use(template)
        plate = Plate.with_uuid(params.dig(:data, :attributes, :plate_uuid)).first
        template.record_template_use(plate, enforce_uniqueness?)
      end
    end
  end
end
