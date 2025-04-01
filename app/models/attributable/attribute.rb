# frozen_string_literal: true

module Attributable
  # Summarises the validations for an attribute
  # In addition to the basis rails validation also provides:
  # 1) Information to assist with automatically generating form elements
  # 2) Tools to assist with validating eg. submissions prior to the creation of the
  #    requests themselves
  # 3) Wiping out some fields on the condition of others
  class Attribute # rubocop:todo Metrics/ClassLength
    attr_reader :name, :default

    alias assignable_attribute_name name

    def initialize(owner, name, options = {})
      @owner = owner
      @name = name.to_sym
      @options = options
      @default = options.delete(:default)
      @required = options.delete(:required).present?
      @validator = options.delete(:validator).present?
    end

    def from(record)
      record[name]
    end

    def default_from(origin = nil)
      return nil if origin.nil?
      origin.validator_for(name).default if validator?
    end

    def validator?
      @validator
    end

    def required?
      @required
    end

    def optional?
      !required?
    end

    def integer?
      @options.fetch(:integer, false)
    end

    def float?
      @options.fetch(:positive_float, false)
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
      @options.fetch(:minimum, 0)
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

    # Returns true if the attribute is a boolean select, i.e. a select with
    # true/false values with custom option texts)
    #
    # @return [Boolean] True if the attribute is a boolean select
    def boolean_select?
      @options.key?(:boolean_select)
    end

    # Returns the select options for the boolean select, i.e. mapping of hash
    # or array option texts to true/false values.
    #
    # @return [Hash] The select options for the boolean select
    def select_options
      @options[:select_options]
    end

    # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
    def configure(model) # rubocop:todo Metrics/CyclomaticComplexity
      conditions = @options.slice(:if, :on)
      save_blank_value = @options.delete(:save_blank)
      allow_blank = save_blank_value
      model.with_options(conditions) do |object|
        # false.blank? == true, so we exclude booleans here, they handle themselves further down.
        object.validates_presence_of(name) if required? && !boolean?
        object.with_options(allow_nil: optional?, allow_blank: allow_blank) do |required|
          required.validates_inclusion_of(name, in: [true, false]) if boolean?
          if integer? || float?
            required.validates name, numericality: { only_integer: integer?, greater_than_or_equal_to: minimum }
          end
          required.validates_inclusion_of(name, in: selection_values, allow_false: true) if fixed_selection?
          required.validates_format_of(name, with: valid_format) if valid_format?

          # Custom validators should handle nil explicitly.
          required.validates name, custom: true, allow_nil: false if validator?
        end
      end

      unless save_blank_value
        model.class_eval(
          "
          before_validation do |record|
            value = record.#{name}
            record.#{name}= nil if value and value.blank?
          end
        "
        )
      end

      return if conditions[:if].nil?

      model.class_eval(
        "
        before_validation do |record|
          record.#{name}= nil unless record.#{conditions[:if]}
        end
      "
      )
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

    def self.find_display_name(klass, name)
      translation = I18n.t("metadata.#{klass.name.underscore.tr('/', '.')}.#{name}")

      return translation[:label] if translation.is_a?(Hash) # translation found, we return the label

      superclass = klass.superclass
      if superclass == ActiveRecord::Base
        # We've reached the top and have no translation
        translation # shoulb be an error message, so that's ok
      else
        # We still have a parent class
        find_display_name(superclass, name) # Walk up the class hierarchy and try again
      end
    end

    def display_name
      Attribute.find_display_name(@owner, name)
    end

    #
    # Find the default value for the attribute.
    # Validator source needs to respond to #validator_for
    # such as metadata or a request type.
    # @param validator_source [#validator_for] In cases where defaults are dynamic
    # such as those on request types, you can pass in the validators here.
    #
    # @return [type] [description]
    def find_default(validator_source = nil)
      default_from(validator_source) || default
    end

    def kind
      return FieldInfo::SELECTION if selection?
      return FieldInfo::BOOLEAN if boolean?
      return FieldInfo::NUMERIC if integer? || float?
      return FieldInfo::BOOLEAN_SELECT if boolean_select?

      FieldInfo::TEXT
    end

    def selection_from_metadata(validator_source)
      return nil if validator_source.blank?
      validator_source.validator_for(name).valid_options.to_a if validator?
    end

    def selection_options(validator_source)
      selection_values || selection_from_metadata(validator_source) || []
    end

    def to_field_info(validator_source = nil)
      options = {
        # TODO[xxx]: currently only working for metadata, the only place attributes are used
        display_name: display_name,
        key: assignable_attribute_name,
        default_value: find_default(validator_source),
        kind: kind,
        required: required?,
        select_options: select_options
      }
      options.update(selection: selection_options(validator_source)) if selection?
      options.update(step: 1, min: minimum) if integer?
      options.update(step: 0.1, min: 0) if float?
      FieldInfo.new(options)
    end
  end
end
