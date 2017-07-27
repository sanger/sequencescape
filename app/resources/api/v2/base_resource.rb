# frozen_string_literal: true

module Api
  module V2
    # Provides extensions to JSONAPI::Resource as well as global behaviour
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaseResource < JSONAPI::Resource
      abstract
      # This extension allows the readonly property to be used on attributes/relationships
      # prior to the 0.10 upgrade. This avoids the need to override updatable_fields on
      # every resource. Readonly does not work on attributes in 0.9 by default
      # This can be removed as soon as we update to 0.10, which is currently only in alpha
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] }.keys
      end

      # Eager load specified models by default. Useful when attributes are
      # dependent on an associated model.
      def self.default_includes(*inclusions)
        @default_includes = inclusions
      end

      # Extends the default bheaviour to add our default inclusions if provided
      def self.apply_includes(records, options = {})
        if @default_includes.present?
          super.includes(*@default_includes)
        else
          super
        end
      end
    end
  end
end
