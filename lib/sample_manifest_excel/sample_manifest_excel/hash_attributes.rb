module SampleManifestExcel
  module HashAttributes

    extend ActiveSupport::Concern
    include Comparable

    module ClassMethods
      def set_attributes(*attributes)

        options = attributes.extract_options!

        attr_accessor *attributes

        define_method :attributes do
          attributes
        end

        define_method :default_attributes do
          options[:defaults] || {}
        end

        define_method :add_attributes do |attrs = {}|
          attrs.with_indifferent_access.slice(*self.attributes).each do |name, value|
            send("#{name}=", value)
          end
        end

        alias_method :update_attributes, :add_attributes

        define_method :create_attributes do |attrs = {}|
          add_attributes default_attributes.merge(attrs)
        end

      end
    end

    def to_a
      instance_variables.collect { |v| instance_variable_get(v) }.compact
    end

    def <=>(other)
      to_a <=> other.to_a
    end

  end
end