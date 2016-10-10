module SampleManifestExcel

  ##
  # provides a number of methods to manage attributes.
  # The set attributes class method allows the user to define attribute accessors.
  # Called like so:
  #  set_attributes :attr_1, :attr_2, :attr_3, defaults: { attr_1: "attr_1"}
  # The set_attributes method will define the following methods:
  #  - create_attributes: create an instance variable for each of the passed hash attributes.
  #    Any passed attributes that are not defined by set_attributes will raise an error.
  #    If an attribute is not defined and a default attribute exists then an instance variables
  #    is set to the default.
  # - attributes: A list of defined attributes.
  # - default_attributes: A hash of default attributes and their values.
  # - update_attributes: update an instance variable for each of the passed hash attributes. Will not reset
  #   any default attributes. Any passed attributes that are not defined by set_attributes are ignored.
  module HashAttributes

    extend ActiveSupport::Concern
    include Comparable

    module ClassMethods


      def set_attributes(*attributes)

        options = attributes.extract_options!

        attr_accessor(*attributes)

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

    ##
    # returns an array of the instance variables removing null values.
    def to_a
      attributes.collect { |v| instance_variable_get("@#{v}") }.compact
    end

    ##
    # Two objects are comparable if all of their instance variables that are present
    # are comparable.
    def <=>(other)
      return unless other.is_a?(self.class)
      to_a <=> other.to_a
    end

  end
end
