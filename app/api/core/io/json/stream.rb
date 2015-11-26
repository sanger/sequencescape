#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2014 Genome Research Ltd.
module ::Core::Io::Json
  class Stream
    def initialize(buffer)
      @buffer, @have_output_value = buffer, []
    end

    def open(&block)
      flush do
        unencoded('{')
        yield(self)
        unencoded('}')
      end
    end

    def array(attribute, objects, &block)
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
      case
      when object.nil?              then unencoded('null')
      when Symbol                        === object    then string_encode(object)
      when TrueClass                     === object    then unencoded('true')
      when FalseClass                    === object    then unencoded('false')
      when String                        === object    then string_encode(object)
      when Fixnum                        === object    then unencoded(object.to_s)
      when Float                         === object    then unencoded(object.to_s)
      when Date                          === object    then string_encode(object)
      when ActiveSupport::TimeWithZone   === object    then string_encode(object.to_s)
      when Time                          === object    then string_encode(object.to_s(:compatible))
      when Hash                          === object    then hash_encode(object, options)
      when object.respond_to?(:zip) then array_encode(object) { |o| encode(o, options) }
      else object_encode(object, options)
      end
    end

    def object_encode(object, options)
      open do
        ::Core::Io::Registry.instance.lookup_for_object(object).object_json(
          object, options.merge(
            :stream => self,
            :object => object,
            :nested => true
          )
        )
      end
    end
    private :object_encode

    def named(attribute, &block)
      unencoded(',') if have_output_value?
      encode(attribute)
      unencoded(':')
      yield
    ensure
      have_output_value
    end

    def hash_encode(hash, options)
      open do |stream|
        hash.each do |k,v|
          stream.attribute(k.to_s, v, options)
        end
      end
    end
    private :hash_encode

    def array_encode(array, &block)
      unencoded('[')
      array.zip([',']*(array.size-1)).each do |value, separator|
        yield(value)
        unencoded(separator) unless separator.nil?
      end unless array.empty?
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

    def flush(&block)
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
