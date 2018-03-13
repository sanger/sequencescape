# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2014,2015,2016 Genome Research Ltd.

module ::Core::Io::Json
  class Stream
    # An interface matches object who respond to the provided method
    class Interface
      def initialize(interface)
        @method = interface
      end

      def ===(other)
        other.respond_to?(:zip)
      end
    end

    ZIPPABLE = Interface.new(:zip).freeze

    def initialize(buffer)
      @buffer, @have_output_value = buffer, []
    end

    def open
      flush do
        unencoded('{')
        yield(self)
        unencoded('}')
      end
    end

    def array(attribute, objects)
      named(attribute) do
        array_encode(objects) { |v| yield(self, v) }
      end
    end

    def attribute(attribute, value, options = {})
      named(attribute) do
        encode(value, options)
      end
    end

    def block(attribute, &block)
      named(attribute) { open(&block) }
    end

    def encode(object, options = {})
      case object
      when NilClass                    then unencoded('null')
      when Symbol                      then string_encode(object)
      when TrueClass                   then unencoded('true')
      when FalseClass                  then unencoded('false')
      when String                      then string_encode(object)
      when Integer                     then unencoded(object.to_s)
      when Float                       then unencoded(object.to_s)
      when Date                        then string_encode(object)
      when ActiveSupport::TimeWithZone then string_encode(object.to_s)
      when Time                        then string_encode(object.to_s(:compatible))
      when Hash                        then hash_encode(object, options)
      when ZIPPABLE                    then array_encode(object) { |o| encode(o, options) }
      else object_encode(object, options)
      end
    end

    def object_encode(object, options)
      open do
        ::Core::Io::Registry.instance.lookup_for_object(object).object_json(
          object, options.merge(
                    stream: self,
                    object: object,
                    nested: true
          )
        )
      end
    end
    private :object_encode

    def named(attribute)
      unencoded(',') if have_output_value?
      encode(attribute)
      unencoded(':')
      yield
    ensure
      have_output_value
    end

    def hash_encode(hash, options)
      open do |stream|
        hash.each do |k, v|
          stream.attribute(k.to_s, v, options)
        end
      end
    end
    private :hash_encode

    def array_encode(array)
      unencoded('[')
      # Use length rather than size, as otherwise we perform
      # a count query. Not only is this unnecessary, but seems
      # to generate inaccurate numbers in some cases.
      last_item = array.length - 1
      array.each_with_index do |value, index|
        yield(value)
        unencoded(',') unless index == last_item
      end
      unencoded(']')
    end
    private :array_encode

    def string_encode(object)
      unencoded(object.to_json)
    end
    private :string_encode

    def unencoded(value)
      @buffer.write(value)
    end
    private :unencoded

    def flush
      @have_output_value[0] = false
      yield
      @buffer.flush
    ensure
      @have_output_value.shift
    end
    private :flush

    def have_output_value?
      @have_output_value.first
    end
    private :have_output_value?

    def have_output_value
      @have_output_value[0] = true
    end
    private :have_output_value
  end
end
