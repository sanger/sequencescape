# frozen_string_literal: true
module Core::Io::Json::Grammar
  module Intermediate
    attr_reader :children

    def initialize(children)
      @children = children || {}
    end

    def leaf(name, attribute)
      @children[name] ||= Leaf.new(name, attribute)
    end

    def [](name)
      @children[name] ||= Node.new(name)
    end

    def call(object, options, stream)
      process_children(object, options, stream)
    end

    def process_children(object, options, stream)
      @children.each_value { |child| child.call(object, options, stream) }
    end
    private :process_children

    def merge(node)
      yield(node.merge_children_with(self))
    end

    # rubocop:todo Metrics/MethodLength
    def merge_children_with(node) # rubocop:todo Metrics/AbcSize
      (node.children.keys + @children.keys)
        .uniq
        .each_with_object({}) do |k, store|
          cloned =
            if @children.key?(k) && node.children.key?(k)
              node.children[k].merge(@children[k])
            elsif @children.key?(k)
              @children[k]
            elsif node.children.key?(k)
              node.children[k]
            else
              raise 'Odd, how did that happen?'
            end

          store[k] = cloned
        end
    end

    # rubocop:enable Metrics/MethodLength

    def inspect
      @children.values.inspect
    end

    def duplicate
      yield(@children.deep_dup)
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

    delegate :json_root, to: :@owner

    def encode(object, options)
      object_encoder(object, options).call(object, options, options[:stream])
    end

    # To encode an individual object we use our JSON serialization tree, merged with the actions
    # tree from the endpoint would handle this object.
    def object_encoder(object, options)
      return self unless object.respond_to?(:uuid)

      instance_handler = options[:handled_by].send(:endpoint_for_object, object).instance_handler
      instance_handler.tree_for(object, options).merge(self) { |children| self.class.new(@owner, children) }
    rescue Core::Endpoint::BasicHandler::EndpointLookup::MissingEndpoint => e
      # There is no endpoint for this, even though it has a UUID!
      self
    end
    private :object_encoder

    def call(object, options, stream)
      rooted_json(stream, options[:nested]) do |stream|
        stream.attribute('created_at', object.created_at)
        stream.attribute('updated_at', object.updated_at)
        super(object, options, stream)
      end
    end

    def rooted_json(stream, nested, &)
      return yield(stream) if nested

      stream.block(json_root, &)
    end
    private :rooted_json

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
      stream.block(@name) { |stream| super(object, options, stream) }
    end

    def dup
      duplicate { |children| self.class.new(@name, children) }
    end

    def merge(node)
      super do |children|
        self.class.new(@name, children)
      end
    end

    def inspect
      "Node<#{@name},#{super}>"
    end
  end

  class Leaf
    attr_reader :name

    def initialize(name, attribute)
      @name = name
      @attribute = attribute.pop
      @attribute_path = attribute
    end

    def call(object, options, stream)
      value =
        @attribute_path.inject(object) do |o, k|
          return if o.nil?

          o.send(k)
        end or return

      stream.attribute(@name, value.send(@attribute), options)
    end

    def dup
      attribute = @attribute_path.dup.tap { |p| p << @attribute }
      self.class.new(name, attribute)
    end

    def merge(_node)
      raise 'Cannot merge into a leaf as it is attribute only!'
    end

    def merge_children_with(node)
      key = "_#{name}"
      raise "Cannot merge as existing leaf node '#{key}'" if node.children.key?(key)

      node.children.merge(key => self)
    end

    def inspect
      "Leaf<#{@name},#{@attribute},#{@attribute_path.inspect}>"
    end
  end

  module Resource
    def resource_details(endpoint, object, options, stream)
      stream.block('actions') do |nested_stream|
        endpoint
          .send(:actions, object, options.merge(target: object))
          .map { |action, url| nested_stream.attribute(action, url) }
        actions(object, options, nested_stream)
      end
      stream.attribute('uuid', object.uuid)
    end
  end

  class Actions
    include Intermediate
    include Resource

    def initialize(endpoint, children = nil)
      super(children)
      @endpoint = endpoint
    end

    def call(object, options, stream)
      resource_details(@endpoint, object, options, stream)
    end

    def actions(object, options, stream)
      process_children(object, options, stream)
    end

    def merge(_)
      raise 'Cannot merge into an actions leaf as it is actions only!'
    end

    def dup
      self.class.new(@endpoint)
    end

    def inspect
      "Actions<#{super}>"
    end
  end
end
