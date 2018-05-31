
# This module can be included into ActiveRecord::Base classes to get the ability to specify the attributes
# that are present.  You can think of this as metadata being stored about the column in the table: it's
# default value, whether it's required, if it has a set of values that are acceptable, or if it's numeric.
# Use the class method 'attribute' to define your attribute:
#
#   attribute(:foo, :required => true)
#   attribute(:bar, :default => 'Something', :in => [ 'Something', 'Other thing' ])
#   attribute(:numeric, :integer => true)
#   attribute(:dependent, :required => true, :if => ->(r) { r.foo == 'Yep' })
#
# Attribute information can be retrieved from the class through 'attributes', and each one of the attributes
# you define can be converted to a FieldInfo instance using 'to_field_info'.

require_dependency 'attributable/custom_validator'
require_dependency 'attributable/attribute'
require_dependency 'attributable/association'

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

  def attribute_details_for(*args)
    self.class.attribute_details_for(*args)
  end

  def instance_defaults
    attribute_details.each_with_object({}) do |attribute, hash|
      hash[attribute.name] = attribute.default_from(self) if attribute.validator?
    end
  end

  def attribute_value_pairs
    attribute_details.each_with_object({}) do |attribute, hash|
      hash[attribute] = attribute.from(self)
    end
  end

  def association_value_pairs
    association_details.each_with_object({}) do |attribute, hash|
      hash[attribute] = attribute.from(self)
    end
  end

  def field_infos
    attribute_details.map do |detail|
      detail.to_field_info(nil, self)
    end
  end

  def required?(field)
    attribute   = attribute_details.detect { |attribute| attribute.name == field }
    attribute ||= association_details.detect { |association| :"#{association.name}_id" == field }
    attribute.try(:required?)
  end

  module ClassMethods
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

    def association(name, instance_method, options = {})
      association = Association.new(self, name, instance_method, options)
      association.configure(self)
      self.association_details += [association]
    end

    def defaults
      @defaults ||= attribute_details.each_with_object({}) do |attribute, hash|
        hash[attribute.name] = attribute.default
      end
    end

    def attribute_names
      attribute_details.map(&:name)
    end

    def attribute_details_for(attribute_name)
      attribute_details.detect { |d| d.name.to_sym == attribute_name.to_sym } or raise StandardError, "Unknown attribute #{attribute_name}"
    end
  end
end
