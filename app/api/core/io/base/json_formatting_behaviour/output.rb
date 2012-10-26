module ::Core::Io::Base::JsonFormattingBehaviour::Output
  class Stream
    class ArrayStream
      def initialize
        @elements = []
      end

      def object(&block)
        stream = Stream.new
        yield(stream)
        @elements.push(stream.to_hash)
      end

      def to_a
        @elements
      end
    end

    def initialize(hash = {})
      @hash = hash
    end

    def []=(attribute, value)
      @hash[attribute] = value
    end

    def [](attribute, force = false, &block)
      result = case
        when @hash.key?(attribute) then @hash[attribute]
        when force                 then @hash[attribute] = {}
        else                            nil
      end
      yield(self.class.new(result)) unless result.nil?
    end

    def array(attribute, objects, &block)
      array_stream = ArrayStream.new
      objects.each do |object|
        array_stream.object do |object_stream|
          yield(object_stream, object)
        end
      end
      @hash[attribute] = array_stream.to_a
    end

    def to_hash
      @hash
    end
  end

  def generate_object_to_json_mapping(attribute_to_json)
    code = attribute_to_json.sort_by(&:first).map do |attribute, json|
      json_path = json.split('.')
      json_leaf = json_path.pop

      attribute_path = attribute.split('.').map(&:to_sym)
      attribute_leaf = attribute_path.pop
      %Q{
        handle_attribute(object, #{attribute_leaf.inspect}, #{attribute_path.inspect}, options) do |value, force|
          #{json_path.reverse.inspect}.inject(
            lambda { |r| r[#{json_leaf.inspect}] = value }
          ) do |caller,attribute|
            lambda { |r| r.send(:[], attribute, force, &caller) }
          end.call(result)
        end
      }
    end

    line = __LINE__ + 1
    class_eval(%Q{
      def self.object_json(object, options)
        rooted_json(options) do |result|
          default_json(result, object, options)
          #{code.join("\n")}
        end
      end
    }, "#{__FILE__}(#{self.name})", line)

#    separator = "#{'='*30} #{self.name} #{'='*30}"
#    $stderr.puts separator
#    code.map { |l| l.split("\n") }.flatten.each_with_index { |l,i| $stderr.puts "#{(line+7+i).to_s.rjust(3)} - #{l}" }
#    $stderr.puts('='*separator.length)
  end

  RETURNED_OBJECTS = [
    Symbol, String, Fixnum, BigDecimal, Float,
    Date, Time, ActiveSupport::TimeWithZone,
    FalseClass, TrueClass
  ]

  def jsonify(object, options)
    case
    when object.nil?         then nil
    when object.is_a?(Array) then object.map { |o| jsonify(o, options) }
    when object.is_a?(Hash)  then Hash[object.map { |k,v| [ jsonify(k, options), jsonify(v, options) ] }]
    when RETURNED_OBJECTS.include?(object.class) then object
    else
      stream = Stream.new
      ::Core::Io::Registry.instance.lookup_for_object(object).as_json(options.merge(
        :object => object,
        :nested => true,
        :stream => stream
      ))
      stream.to_hash
    end
  end
  private :jsonify

  def handle_attribute(object, attribute_name, attribute_path, options)
    target = attribute_path.inject(object) { |o,k| break if o.nil? ; o.send(k) }
    return yield(nil, false) if target.nil?
    yield(jsonify(target.send(attribute_name), options), true)
  end
  private :handle_attribute

  def rooted_json(options, &block)
    return yield(options[:stream]) if options[:nested]
    options[:stream].send(:[], json_root, true, &block)
  end
  private :rooted_json

  def resource_json(result, object, options)
    options[:handled_by].send(:endpoint_for_object, object).instance_handler.generate_action_json(object, options.merge(:stream => result))
    result["uuid"]       = object.uuid
  rescue Core::Endpoint::BasicHandler::EndpointLookup::MissingEndpoint => exception
    # There is no endpoint for this, even though it has a UUID!
  end
  private :resource_json

  def default_json(result, object, options)
    resource_json(result, object, options) if object.respond_to?(:uuid)
    result["created_at"] = object.created_at
    result["updated_at"] = object.updated_at
  end
  private :default_json
end
