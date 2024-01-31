# frozen_string_literal: true

module Api
  module V2
    # Provides extensions to JSONAPI::Resource as well as global behaviour
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class BaseResource < JSONAPI::Resource
      abstract

      # Loaded on the base class so that they can be loaded globally.
      Purpose.descendants.each { |subclass| model_hint model: subclass, resource: :purpose }
      Plate.descendants.each { |subclass| model_hint model: subclass, resource: :plate }
      Tube.descendants.each { |subclass| model_hint model: subclass, resource: :tube }
      Request.descendants.each { |subclass| model_hint model: subclass, resource: :request }

      # This extension allows the readonly property to be used on attributes/relationships
      # prior to the 0.10 upgrade. This avoids the need to override updatable_fields on
      # every resource. Readonly does not work on attributes in 0.9 by default
      # This can be removed as soon as we update to 0.10, which is currently only in alpha
      def self.updatable_fields(context)
        super - _attributes.select { |_attr, options| options[:readonly] }.keys -
          _relationships.select { |_rel_key, rel| rel.options[:readonly] }.keys
      end

      # This extension allows the writeonly property to be used on attributes/relationships.
      # This avoids the need to override fetchable_fields on every resource.
      def fetchable_fields
        super - self.class._attributes.select { |_attr, options| options[:writeonly] }.keys -
          self.class._relationships.select { |_rel_key, rel| rel.options[:writeonly] }.keys
      end

      # Eager load specified models by default. Useful when attributes are
      # dependent on an associated model.
      def self.default_includes(*inclusions)
        @default_includes = inclusions.freeze
      end

      def self.inclusions
        @default_includes || [].freeze
      end

      # TODO: Explain preloading and why we used it here.

      def self.records_for_populate(options = {})
        if @default_includes.present?
          super(options).preload(*inclusions)
        else
          super
        end
      end

      def self.format_default_includes
        @format_default_includes ||= format_inclusions
      end

      def self.format_inclusions
        formatted = Array(inclusions).filter_map { |inclusion| format_single_inclusion(inclusion) }
        formatted.join(',')
      end

      def self.format_single_inclusion(inclusion, parent = nil)
        case inclusion
        when Symbol
          format_symbol_inclusion(inclusion, parent)
        when Hash
          format_hash_inclusion(inclusion, parent)
        when Array
          format_array_inclusion(inclusion, parent)
        end
      end

      def self.format_symbol_inclusion(inclusion, parent)
        resource_klass_for(inclusion.to_s) # Test that the resource exists
        [parent, inclusion].compact.join('.') unless _relationship(inclusion).nil?
      rescue StandardError
        nil
      end

      def self.format_hash_inclusion(inclusion, parent)
        result =
          inclusion.filter_map do |key, value|
            new_parent = format_single_inclusion(key, parent)
            next if new_parent.nil?
            format_single_inclusion(value, new_parent)
          end
        result.join(',') unless result.empty?
      end

      def self.format_array_inclusion(inclusion, parent)
        result = inclusion.filter_map { |value| format_single_inclusion(value, parent) }
        result.join(',') unless result.empty?
      end
    end
  end
end

# {k1: {k2: { k3: 'v3' }}} # => "k1.k2.k3.v3"
