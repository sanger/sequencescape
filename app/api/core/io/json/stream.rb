# frozen_string_literal: true

module Core::Io::Json
  # Custom JSON streaming class to handle streamed serialization of API V1
  # objects
  class Stream # rubocop:todo Metrics/ClassLength
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
      named(attribute) { array_encode(objects) { |v| yield(self, v) } }
    end

    def attribute(attribute, value, options = {})
      named(attribute) { encode(value, options) }
    end

    def block(attribute, &block)
      named(attribute) { open(&block) }
    end

    # rubocop:todo Metrics/MethodLength, Metrics/AbcSize
    def encode(object, options = {}) # rubocop:todo Metrics/CyclomaticComplexity
      case object
      when NilClass
        unencoded('null')
      when Symbol
        string_encode(object)
      when TrueClass
        unencoded('true')
      when FalseClass
        unencoded('false')
      when String
        string_encode(object)
      when Integer
        unencoded(object.to_s)
      when Float
        unencoded(object.to_s)
      when Date
        string_encode(object)
      when ActiveSupport::TimeWithZone
        string_encode(object.to_s)
      when Time
        string_encode(object.to_fs(:compatible))
      when Hash
        hash_encode(object, options)
      when ZIPPABLE
        array_encode(object) { |o| encode(o, options) }
      else
        object_encode(object, options)
      end
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    def object_encode(object, options)
      open do
        ::Core::Io::Registry
          .instance
          .lookup_for_object(object)
          .object_json(object, options.merge(stream: self, object: object, nested: true))
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
      open { |stream| hash.each { |k, v| stream.attribute(k.to_s, v, options) } }
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
