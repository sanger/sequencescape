# frozen_string_literal: true

# There no subclasses at the moment, because we want to keep things simple
# # (especially no need to use a factory)
class FieldInfo
  include ActiveModel::Model

  # A NullFieldInfo when combined with a FieldInfo (via &) will
  # return that field_info
  module NullFieldInfo
    def self.&(other)
      other
    end
  end

  SELECTION = 'Selection'
  TEXT = 'Text'
  BOOLEAN = 'Boolean'
  NUMERIC = 'Numeric'

  # Sorted in order of least restrictiveness
  KIND = [TEXT, NUMERIC, SELECTION, BOOLEAN].freeze

  attr_accessor :display_name, :key, :kind, :default_value, :required, :step, :min, :max, :selection

  def self.for_request_types(request_types)
    attributes = Hash.new(NullFieldInfo)

    request_types.each do |request_type|
      request_type.request_attributes.each { |att| attributes[att.name] &= att.to_field_info(request_type) }
    end

    attributes.values
  end

  # Parameters were only ever used to hold selection
  # This provides legacy support for a handful of serialized field
  # infos in the database
  def parameters=(parameters)
    self.selection = parameters&.fetch(:selection, [])
  end
  deprecate :parameters= => 'set selection directly',
            :deprecator => ActiveSupport::Deprecation.new('14.53.0', 'Sequencescape')

  def parameters
    { min:, max:, step: }
  end

  def value
    default_value || ''
  end

  #
  # Combine two field infos to one with the most limited options
  # @param other [FieldInfo] The FieldInfo to combine with
  #
  # @return [FieldInfo] The new, more restrictive field info
  def &(other) # rubocop:todo Metrics/AbcSize
    raise StandardError, "Attempted to combine #{key} with #{other.key} FieldInfos" unless key == other.key

    dup.tap do |combined|
      # Use set selector to filter to those common to all attributes
      combined.selection = [combined.selection, other.selection].compact.reduce(&:&)
      combined.required ||= other.required

      # If kinds differ, we want to select the most restrictive (eg. selection over numeric)
      combined.kind = other.kind if combined.kind_priority < other.kind_priority
      combined.default_value ||= other.default_value
    end
  end

  def ==(other)
    display_name == other.display_name && key == other.key && kind == other.kind &&
      default_value == other.default_value && selection == other.selection
  end

  def kind_priority
    KIND.index(kind)
  end
end
