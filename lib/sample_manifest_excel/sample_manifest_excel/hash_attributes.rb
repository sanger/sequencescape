module SampleManifestExcel
  module HashAttributes

    extend ActiveSupport::Concern

    module ClassMethods
      def set_attributes(*attributes)

        defaults = attributes.extract_options!

        attr_accessor *attributes

        define_method :attributes do
          attributes
        end

        define_method :default_attributes do
          defaults || {}
        end

        define_method :add_attributes do |attrs = {}|
          attrs.slice(*self.attributes).each do |name, value|
            send("#{name}=", value)
          end
        end

        alias_method :update_attributes, :add_attributes

        define_method :create_attributes do |attrs = {}|
          add_attributes default_attributes.merge(attrs)
        end

      end
    end

  end
end