# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

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

  class CustomValidator < ActiveModel::EachValidator
    def validate_each(record, attribute, value)
      valid = record.validator_for(attribute).valid_options.include?(value)
      record.errors.add(attribute, 'is not a valid option') unless valid
      valid
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
    def attribute(name, options = {}, override_previous = false)
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

  class Association
    module Target
      def self.extended(base)
        base.class_eval do
          include InstanceMethods
          scope :for_selection, ->() { order(:name) }
        end
      end

      def for_select_association
        for_selection.pluck(:name, :id)
      end

      def default
        nil
      end

      module InstanceMethods
        def for_select_dropdown
          [name, id]
        end
      end
    end

    attr_reader :name

    def initialize(owner, name, method, options = {})
      @owner, @name, @method = owner, name, method
      @required = !!options.delete(:required) || false
      @scope = Array(options.delete(:scope))
    end

    def required?
      @required
    end

    def optional?
      not required?
    end

    def assignable_attribute_name
      :"#{@name}_#{@method}"
    end

    def from(record)
      record.send(@name).send(@method)
    end

    def display_name
      Attribute::find_display_name(@owner, name)
    end

    def kind
      FieldInfo::SELECTION
    end

    def find_default(*_args)
      nil
    end

    def selection?
      true
    end

    def selection_options(_)
      get_scoped_selection.all.map(&@method.to_sym).sort
    end

    def to_field_info(*_args)
      FieldInfo.new(
        display_name: display_name,
        key: assignable_attribute_name,
        kind: kind,
        selection: selection_options(nil)
      )
    end

    def get_scoped_selection
      @scope.inject(@owner.reflections[@name.to_s].klass) { |k, v| k.send(v.to_sym) }
    end
    private :get_scoped_selection

    def configure(target)
      target.class_eval(%Q{
        def #{assignable_attribute_name}=(value)
          record = self.class.reflections['#{@name}'].klass.find_by_#{@method}(value) or
            raise ActiveRecord::RecordNotFound, "Could not find #{@name} with #{@method} \#{value.inspect}"
          send(:#{@name}=, record)
        end

        def #{assignable_attribute_name}
          send(:#{@name}).send(:#{@method})
        end
      })
    end
  end

  class Attribute
    attr_reader :name
    attr_reader :default

    alias_method :assignable_attribute_name, :name

    def initialize(owner, name, options = {})
      @owner, @name, @options = owner, name.to_sym, options
      @default  = options.delete(:default)
      @required = options.delete(:required).present?
      @validator = options.delete(:validator).present?
    end

    def from(record)
      record[name]
    end

    def default_from(origin = nil)
      return nil if origin.nil?
      return origin.validator_for(name).default if validator?
    end

    def validator?
      @validator
    end

    def required?
      @required
    end

    def optional?
      not required?
    end

    def numeric?
      @options.key?(:integer)
    end

    def float?
      @options.key?(:positive_float)
    end

    def boolean?
      @options.key?(:boolean)
    end

    def fixed_selection?
      @options.key?(:in)
    end

    def selection?
      fixed_selection? || @options.key?(:selection)
    end

    def minimum
      @options[:minimum] || 0
    end

    def selection_values
      @options[:in]
    end

    def valid_format
      @options[:with]
    end

    def valid_format?
      valid_format
    end

    def configure(model)
      conditions = @options.slice(:if)
      save_blank_value = @options.delete(:save_blank)
      allow_blank = save_blank_value

      model.with_options(conditions) do |object|
        # false.blank? == true, so we exclude booleans here, they handle themselves further down.
        object.validates_presence_of(name) if required? && !boolean?
        object.with_options(allow_nil: optional?, allow_blank: allow_blank) do |required|
          required.validates_inclusion_of(name, in: [true, false]) if boolean?
          required.validates_numericality_of(name, only_integer: true) if numeric?
          required.validates_numericality_of(name, greater_than: 0) if float?
          required.validates_inclusion_of(name, in: selection_values, allow_false: true) if fixed_selection?
          required.validates_format_of(name, with: valid_format) if valid_format?
          required.validates name, custom: true if validator?
        end
      end

      unless save_blank_value
        model.class_eval("
          before_validation do |record|
            value = record.#{name}
            record.#{name}= nil if value and value.blank?
          end
        ")
      end

      unless (condition = conditions[:if]).nil?
        model.class_eval("
          before_validation do |record|
            record.#{name}= nil unless record.#{condition}
          end
        ")
      end
    end

    def self.find_display_name(klass, name)
      translation = I18n.t("metadata.#{klass.name.underscore.tr('/', '.')}.#{name}")
      if translation.is_a?(Hash) # translation found, we return the label
        return translation[:label]
      else
        superclass = klass.superclass
        if superclass != ActiveRecord::Base # a subclass , try the superclass name scope
          return find_display_name(superclass, name)
        else # translation not found
          return translation # shoulb be an error message, so that's ok
        end
      end
    end

    def display_name
      Attribute::find_display_name(@owner, name)
    end

    def find_default(object = nil, metadata = nil)
      default_from(metadata) || object.try(name) || default
    end

    def kind
      return FieldInfo::SELECTION if selection?
      return FieldInfo::BOOLEAN if boolean?
      return FieldInfo::NUMERIC if numeric? || float?
      FieldInfo::TEXT
    end

    def selection_from_metadata(metadata)
      return nil unless metadata.present?
      return metadata.validator_for(name).valid_options.to_a if validator?
    end

    def selection_options(metadata)
      selection_values || selection_from_metadata(metadata) || []
    end

    def to_field_info(object = nil, metadata = nil)
      options = {
        # TODO[xxx]: currently only working for metadata, the only place attributes are used
        display_name: display_name,
        key: assignable_attribute_name,
        default_value: find_default(object, metadata),
        kind: kind,
        required: required?
      }
      options.update(selection: selection_options(metadata)) if selection?
      options.update(step: 1, min: minimum) if numeric?
      options.update(step: 0.1, min: 0) if float?
      FieldInfo.new(options)
    end
  end
end
