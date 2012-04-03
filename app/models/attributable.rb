# This module can be included into ActiveRecord::Base classes to get the ability to specify the attributes
# that are present.  You can think of this as metadata being stored about the column in the table: it's
# default value, whether it's required, if it has a set of values that are acceptable, or if it's numeric.
# Use the class method 'attribute' to define your attribute:
#
#   attribute(:foo, :required => true)
#   attribute(:bar, :default => 'Something', :in => [ 'Something', 'Other thing' ])
#   attribute(:numeric, :integer => true)
#   attribute(:dependent, :required => true, :if => lambda { |r| r.foo == 'Yep' })
#
# Attribute information can be retrieved from the class through 'attributes', and each one of the attributes
# you define can be converted to a FieldInfo instance using 'to_field_info'.
module Attributable
  def self.included(base)
    base.extend(ClassMethods)
    base.class_eval do
      # NOTE: Do not use 'attributes' because that's an ActiveRecord internal name
      class_inheritable_reader :attribute_details
      write_inheritable_attribute(:attribute_details, [])
      class_inheritable_reader :association_details
      write_inheritable_attribute(:association_details, [])
    end
  end

  def attribute_details_for(*args)
    self.class.attribute_details_for(*args)
  end

  def attribute_value_pairs
    self.class.attribute_details.inject({}) do |hash, attribute|
      hash.tap { hash[attribute] = attribute.from(self) }
    end
  end

  def association_value_pairs
     self.class.association_details.inject({}) do |hash, attribute|
       hash.tap { hash[attribute] = attribute.from(self) }
     end
   end

  def field_infos
    self.class.attribute_details.map(&:to_field_info)
  end

  def required?(field)
    attribute   = self.class.attribute_details.detect { |attribute| attribute.name == field }
    attribute ||= self.class.association_details.detect { |association| :"#{association.name}_id" == field }
    attribute.try(:required?)
  end

  module ClassMethods
    def attribute(name, options = {}, override_previous = false)
      attribute = Attribute.new(self, name, options)
      attribute.configure(self)

      if override_previous
        attribute_details.delete_if { |a| a.name == name }
        attribute_details.push(attribute)
      elsif attribute_details.detect { |a| a.name == name }.nil?
        attribute_details.push(attribute)
      end
    end

    def association(name, instance_method, options = {})
      association = Association.new(self, name, instance_method, options)
      association.configure(self)
      association_details.push(association)
    end

    def defaults
      attribute_details.inject({}) do |hash, attribute|
        hash.tap { hash[ attribute.name ] = attribute.default }
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
        end
      end

      def for_select_association
        all(:order => 'name ASC').map(&:for_select_dropdown).compact
      end

      def default
        nil
      end

      module InstanceMethods
        def for_select_dropdown
          [ self.name, self.id ]
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
      not self.required?
    end

    def assignable_attribute_name
      :"#{@name}_#{@method}"
    end

    def from(record)
      record.send(@name).send(@method)
    end

    def to_field_info(*args)
      FieldInfo.new(
        :display_name  => Attribute::find_display_name(@owner,  name),
        :key           => assignable_attribute_name,
        :kind          => FieldInfo::SELECTION,
        :selection     => get_scoped_selection.all.map(&@method.to_sym).sort
      )
    end

    def get_scoped_selection
      @scope.inject(@owner.reflections[@name.to_sym].klass){|k,v| k.send(v.to_sym) }
    end
    private :get_scoped_selection

    def configure(target)
      target.class_eval(%Q{
        def #{assignable_attribute_name}=(value)
          record = self.class.reflections[:#{@name}].klass.find_by_#{@method}(value) or
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

    def initialize(owner, name, options = {})
      @owner, @name, @options = owner, name.to_sym, options
      @default  = options.delete(:default)
      @required = !!options.delete(:required) || false
    end

    def from(record)
      record[self.name]
    end

    def required?
      @required
    end

    def optional?
      not self.required?
    end

    def numeric?
      @options.key?(:integer)
    end

    def selection?
      @options.key?(:in)
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
        object.validates_presence_of(name) if self.required?
        object.with_options(:allow_nil => self.optional?, :allow_blank => allow_blank) do |required|
          required.validates_numericality_of(name, :only_integer => true) if self.numeric?
          required.validates_inclusion_of(name, :in => self.selection_values, :allow_false => true) if self.selection?
          required.validates_format_of(name, :with => self.valid_format) if self.valid_format?
        end
      end

      unless save_blank_value
        model.before_validation do |record|
          value = record.send(name)
          record.send("#{name}=", nil) if value and value.blank?
        end
      end

      unless (condition = conditions[:if]).nil?
        model.before_validation do |record|
          record[name] = nil unless record.send(condition)
        end
      end
    end

    def self.find_display_name(klass, name)
      translation = I18n.t("metadata.#{ klass.name.underscore.gsub('/', '.') }.#{ name }")
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

    def to_field_info(object = nil)
      options = {
        # TODO[xxx]: currently only working for metadata, the only place attributes are used
        :display_name  => Attribute::find_display_name(@owner,  name),
        :key           => self.name,
        :default_value => object.try(self.name) || self.default,
        :kind          => FieldInfo::TEXT
      }
      options.update(:kind => FieldInfo::SELECTION, :selection => self.selection_values) if self.selection?
      FieldInfo.new(options)
    end
  end
end
