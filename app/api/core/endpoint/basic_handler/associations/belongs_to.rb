module Core::Endpoint::BasicHandler::Associations::BelongsTo
  class Handler
    include Core::Endpoint::BasicHandler::EndpointLookup

    def initialize(name, options, &block)
      @name, @options = name, options
    end

    def as_json(options = {})
      endpoint_details(options) do |endpoint, object|
        options[:uuids_to_ids][object.uuid] = object.id
        action_json = endpoint.instance_handler.as_json(options.merge(:embedded => true, :target => object))
        action_json[:uuid] = object.uuid

        { @options[:json].to_s => action_json }
      end
    end

    def endpoint_details(options)
      object = options[:target].send(@name)
      return { @options[:json].to_s => nil } if object.nil?
      yield(endpoint_for_object(object), object)
    end
    private :endpoint_details
  end

  def initialize
    super
    @endpoints = []
  end

  def belongs_to(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.classify, handler) }
    @endpoints.push(class_handler.new(name, options, &block))
  end

  def as_json(options = {})
    super.tap do |json|
      @endpoints.each do |endpoint|
        json.deep_merge!(endpoint.as_json(options))
      end unless options[:embedded]
    end
  end
end
