module ::Core::Io::Base::JsonFormattingBehaviour::Output
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
      named(attribute) { encode(value, options) }
    end

    def block(attribute, &block)
      named(attribute) { open(&block) }
    end

    def encode(object, options = {})
      case
      when object.nil?              then unencoded('null')
      when Symbol     === object    then string_encode(object)
      when TrueClass  === object    then unencoded('true')
      when FalseClass === object    then unencoded('false')
      when String     === object    then string_encode(object)
      when Fixnum     === object    then unencoded(object.to_s)
      when Float      === object    then unencoded(object.to_s)
      when Date       === object    then string_encode(object.to_s)
      when Time       === object    then string_encode(object.to_s)
      when Hash       === object    then hash_encode(object, options)
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
          stream.attribute(k, v, options)
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
      unencoded(%Q{"#{object}"})
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

  module Tree
    module Intermediate
      def initialize(children)
        @children = children || []
      end

      def leaf(name, attribute)
        attach(Leaf.new(name, attribute))
      end

      def [](name)
        @children.detect { |n| n.name == name } || attach(Node.new(name))
      end

      def attach(node)
        node.tap { |n| @children.push(n) }
      end
      private :attach

      def call(object, options, stream)
        @children.each do |child|
          child.call(object, options, stream)
        end
      end

      def inspect
        @children.inspect
      end

      def duplicate(&block)
        yield(@children.map(&:dup))
      end
      private :duplicate
    end

    class Root
      include Intermediate

      def initialize(owner, children = nil)
        super(children)
        @owner = owner
      end

      def for(owner)
        duplicate { |children| self.class.new(owner, children) }
      end

      delegate :json_root, :to => :@owner

      def encode(object, options)
        call(object, options, options[:stream])
      end

      def call(object, options, stream)
        rooted_json(stream, options[:nested]) do |stream|
          default_json(stream, object, options)
          super(object, options, stream)
        end
      end

      def rooted_json(stream, nested, &block)
        return yield(stream) if nested
        stream.block(json_root, &block)
      end
      private :rooted_json

      def resource_json(result, object, options)
        options[:handled_by].send(:endpoint_for_object, object).instance_handler.generate_action_json(object, options.merge(:stream => result))
        result.attribute('uuid', object.uuid)
      rescue Core::Endpoint::BasicHandler::EndpointLookup::MissingEndpoint => exception
        # There is no endpoint for this, even though it has a UUID!
      end
      private :resource_json

      def default_json(result, object, options)
        resource_json(result, object, options) if object.respond_to?(:uuid)
        result.attribute('created_at', object.created_at)
        result.attribute('updated_at', object.updated_at)
      end
      private :default_json

      def inspect
        "Root<#{super}>"
      end
    end

    class Node
      include Intermediate
      attr_reader :name

      def initialize(name, children = nil)
        super(children)
        @name = name
      end

      def call(object, options, stream)
        stream.block(@name) do |stream|
          super(object, options, stream)
        end
      end

      def dup
        duplicate { |children| self.class.new(@name, children) }
      end

      def inspect
        "Node<#{@name},#{super}>"
      end
    end

    class Leaf
      attr_reader :name

      def initialize(name, attribute)
        @name           = name
        @attribute      = attribute.pop
        @attribute_path = attribute
      end

      def call(object, options, stream)
        value = @attribute_path.inject(object) { |o,k| return if o.nil? ; o.send(k) } or return
        stream.attribute(@name, value.send(@attribute), options)
      end

      def dup
        attribute = @attribute_path.dup.tap { |p| p << @attribute }
        self.class.new(name, attribute)
      end

      def inspect
        "Leaf<#{@name},#{@attribute},#{@attribute_path.inspect}>"
      end
    end
  end

  def json_code_tree
    Tree::Root.new(self)
  end

  def generate_object_to_json_mapping(attribute_to_json)
    # Sort the attribute_to_json map such that the JSON elements are in order, thus ensuring that
    # we will only open and close blocks as we go.  Then build a tree that can be executed against
    # an object to generate the JSON appropriately.
    tree = attribute_to_json.sort_by(&:last).map do |attribute, json|
      [ json.split('.'), attribute.split('.').map(&:to_sym) ]
    end.inject(json_code_tree.for(self)) do |tree, (json_path, attribute_path)|
      tree.tap do
        json_leaf = json_path.pop
        json_path.inject(tree) { |node,step| node[step] }.leaf(json_leaf, attribute_path)
      end
    end

    # Now we can generate a method that will use that tree to encode an object to JSON.
    self.singleton_class.send(:define_method, :json_code_tree) { tree }
    self.singleton_class.send(:define_method, :object_json, &tree.method(:encode))
  end
end
