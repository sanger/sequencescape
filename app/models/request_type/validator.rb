# frozen_string_literal: true
##
# A request type validator belongs to a request type, and is responsible for
# validating a single request option
# request_option => The option that will be validated
# valid_options  => A serialized object that responds to include? Returning true if the option is present
#                   It should also return an array of valid options in response to to_a
class RequestType::Validator < ApplicationRecord
  class LibraryTypeValidator
    attr_reader :request_type_id

    def initialize(request_type_id)
      @request_type_id = request_type_id
    end

    def request_type
      RequestType.find(request_type_id)
    end

    def include?(option)
      request_type.library_types.where(name: option).pluck(:name).include?(option)
    end

    def default
      request_type.default_library_type.try(:name)
    end

    def to_a
      request_type.library_types.pluck(:name).sort
    end
    delegate :to_sentence, to: :to_a
  end

  # Validates that the request type provided has a relation with a provided
  # flowcell type name
  class FlowcellTypeValidator
    attr_reader :request_type_key

    def initialize(request_type_key)
      @request_type_key = request_type_key
    end

    def request_type
      RequestType.find_by(key: request_type_key)
    end

    def include?(option)
      return true if option.nil?
      request_type.flowcell_types.exists?(name: option)
    end

    def to_a
      request_type.flowcell_types.pluck(:name).sort
    end
    delegate :to_sentence, to: :to_a

    def allow_blank?
      true
    end
  end

  ##
  # Array class that lets you set a default value
  # If first argument is an array, second argument is assumed to be default
  # Raises exception is default is not in the array
  # In all other cases passes argument to standard array initializer
  class ArrayWithDefault
    attr_accessor :default

    def initialize(array, default)
      raise StandardError, 'Default is not in array' unless array.include?(default)

      @default = default
      @array = array
    end

    def method_missing(method, ...)
      @array.send(method, ...)
    end

    def include?(option)
      # We have to define include specifically
      @array.include?(option)
    end

    def to_a
      @array
    end
  end

  # A NullValidator is used if no specific validator is provided.
  # It accepts everything
  class NullValidator
    def validate?(_value)
      true
    end

    def default
      nil
    end

    def valid_options
      []
    end
  end

  belongs_to :request_type, optional: false
  validates :request_option, :valid_options, presence: true
  serialize :valid_options, coder: YAML

  delegate :include?, to: :valid_options

  def validate?(value)
    valid_options.include?(value)
  end

  def options
    valid_options.to_a
  end

  def default
    valid_options.respond_to?(:default) ? valid_options.default : nil
  end

  def type_cast
    { 'read_length' => :to_i, 'insert_size' => :to_i }[request_option]
  end

  def allow_blank?
    return false unless valid_options.respond_to? :allow_blank?
    valid_options.allow_blank?
  end
end
