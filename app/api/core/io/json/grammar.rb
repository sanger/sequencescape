module ::Core::Io::Json::Grammar
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
      instance_handler = options[:handled_by].send(:endpoint_for_object, object).instance_handler
      instance_handler.generate_action_json(object, options.merge(:stream => result, :target => object))
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
