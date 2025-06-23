# frozen_string_literal: true

# This module can be included into ActiveRecord::Base classes to get the ability to specify the attributes
# that are present.  You can think of this as metadata being stored about the column in the table: it's
# default value, whether it's required, if it has a set of values that are acceptable, or if it's numeric.
# Use the class method 'attribute' to define your attribute:
#
# @example Some example attributes
#   custom_attribute(:foo, :required => true)
#   custom_attribute(:bar, :default => 'Something', :in => [ 'Something', 'Other thing' ])
#   custom_attribute(:numeric, :integer => true)
#
# Attribute information can be retrieved from the class through 'attributes', and each one of the attributes
# you define can be converted to a FieldInfo instance using 'to_field_info'.
module Attributable
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      # NOTE: Do not use 'attributes' because that's an ActiveRecord internal name
      class_attribute :attribute_details, instance_writer: false
      self.attribute_details = []
      class_attribute :association_details, instance_writer: false
      self.association_details = []
    end
  end

  def attribute_details_for(*)
    self.class.attribute_details_for(*)
  end

  def instance_defaults
    attribute_details.each_with_object({}) do |attribute, hash|
      hash[attribute.name] = attribute.default_from(self) if attribute.validator?
    end
  end

  # If we've eager loaded metadata, then we may be using the base class, rather than
  # subclass specific forms. We can override the details used here
  def attribute_value_pairs(details = attribute_details)
    details.index_with { |attribute| attribute.from(self) }
  end

  # If we've eager loaded metadata, then we may be using the base class, rather than
  # subclass specific forms. We can override the details used here
  def association_value_pairs(details = association_details)
    details.index_with { |attribute| attribute.from(self) }
  end

  def field_infos
    attribute_details.map { |detail| detail.to_field_info(self) }
  end

  def required?(field)
    field_details =
      attribute_details.detect { |attribute| attribute.name == field } ||
      association_details.detect { |association| field == :"#{association.name}_id" }
    field_details.try(:required?)
  end

  # Class methods for attribute configuration
  module ClassMethods
    #
    # Define a custom attribute with the provided name. Will automatically generate:
    #   - Validations
    #   - Form helpers
    #   - Accessioning tie-ins
    #   - Convert blank attributes to nil
    # @note Heavy on meta-programming here. There behaviour could also be tidied up and simplified significantly.
    # @param name [Symbol,String] The name of the attribute to generate
    # @option options [Object] :default A default value for the option. (Not a proc/lambda)
    # @option options [Boolean] :required (false) Whether the option is required or not
    # @option options [Boolean] :validator (false) Set to true to defer validation to the #validator_for method
    # @option options [Boolean] :integer (false) The attribute should be an integer
    # @option options [Boolean] :positive_float (false) The attribute should be a float, greater than 0
    # @option options [Boolean] :boolean (false) The attribute should be true or false. WARNING! Currently just tests
    #                                            presence of the key, not actual value. Thus false=true.
    # @option options [Array] :in (nil) The attribute is a selection that must be included in the array.
    # @option options [Boolean] :selection (false) The attribute is a selection generated dynamically from
    #                                              #validator_for
    # @option options [Numeric] :minimum (0) The minimum value for an integer. WARNING! Inconsistently implemented for
    #                                        floats
    # @option options [Regexp] :with (nil) Regexp for validating the attribute
    # @option options [Symbol] :if (nil) Passed through to the rails validator and will also switch persistence of
    #                                    the attribute based on the condition.
    # @option options [Symbol] :on (nil) Passed through to the rails validator. (eg. on: :create)
    # @option options [Boolean] :save_blank (false) set to true to disabling setting blank attributes to nil. (UNUSED)
    # @param override_previous = false [type] Override any attributes of the same name on parent classes. (UNUSED)
    #
    # @return [void] Should probably return Attribute, will actually return the array of attributes
    def custom_attribute(name, options = {}, override_previous = false)
      attribute = Attribute.new(self, name, options)
      attribute.configure(self)

      if override_previous
        self.attribute_details = attribute_details.reject { |a| a.name == name }
        self.attribute_details += [attribute]
      elsif self.attribute_details.detect { |a| a.name == name }.nil?
        self.attribute_details += [attribute]
      end
    end

    # Defines an association with the name.
    def association(name, instance_method, options = {})
      association = Association.new(self, name, instance_method, options)
      association.configure(self)
      self.association_details += [association]
    end

    # Returns a hash of default attribute values
    #
    # @return [Hash<String,Object>] Hash of each attribute and its default
    def defaults
      @defaults ||=
        attribute_details.each_with_object({}) { |attribute, hash| hash[attribute.name] = attribute.default }
    end

    # @return [Array<String>] An array of all attribute names
    def attribute_names
      attribute_details.map(&:name)
    end

    #
    # Looks up the Attribute in a attribute_details Array
    # @param attribute_name [String] The name of the attribute to lookup
    #
    # @return [Attributable::Attribute] The matching attribute
    def attribute_details_for(attribute_name)
      attribute_details.detect { |d| d.name.to_sym == attribute_name.to_sym } ||
        raise(StandardError, "Unknown attribute #{attribute_name}")
    end
  end
end
