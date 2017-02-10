# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

##
# A request type validator belongs to a request type, and is responsible for
# validating a single request option
# request_option => The option that will be validated
# valid_options  => A serialized object that responds to include? Returning true if the option is present
#                   It should also return an array of valid options in response to to_a
class RequestType::Validator < ActiveRecord::Base
  class LibraryTypeValidator
    attr_reader :request_type_id
    def initialize(request_type_id)
      @request_type_id = request_type_id
    end

    def request_type
      RequestType.find(request_type_id)
    end

    def include?(option)
      request_type.library_types.map(&:name).include?(option)
    end

    def default
      request_type.default_library_type.try(:name)
    end

    def to_a
      request_type.library_types.map(&:name)
    end
    delegate :to_sentence, to: :to_a
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

    def method_missing(method, *args, &block)
      @array.send(method, *args, &block)
    end

    def include?(option)
      # We have to define include specifically
      @array.include?(option)
    end

    def to_a
      @array
    end
  end

  belongs_to :request_type
  validates :request_type, :request_option, :valid_options, presence: true
  serialize :valid_options

  delegate :include?, to: :valid_options

  def options
    valid_options.to_a
  end

  def default
    valid_options.respond_to?(:default) ? valid_options.default : nil
  end

  def type_cast
    {
      'read_length'   => :to_i,
      'insert_size'   => :to_i
    }[request_option]
  end
end
