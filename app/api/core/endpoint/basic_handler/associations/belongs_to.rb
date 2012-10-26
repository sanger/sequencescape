module Core::Endpoint::BasicHandler::Associations::BelongsTo
  class Handler
    include Core::Endpoint::BasicHandler::EndpointLookup

    def initialize(name, options, &block)
      @name, @options = name, options
      @throughs = Array(options[:through])
    end

    def generate_action_json(object, options)
      endpoint_details(options) do |endpoint, object|
        options[:stream].block(@options[:json].to_s) do |result|
          result.attribute('uuid', object.uuid)
          endpoint.instance_handler.generate_action_json(
            object,
            options.merge(:stream => result, :embedded => true, :target => object)
          )
        end
      end
    end

    def endpoint_details(options)
      object = @throughs.inject(options[:target]) { |t,s| t.send(s) }.send(@name) || return
      yield(endpoint_for_object(object), object)
    end
    private :endpoint_details
  end

  def initialize
    super
    @endpoints = []
  end

  def belongs_to(name, options, &block)
    class_handler = Class.new(Handler).tap { |handler| self.class.const_set(name.to_s.camelize, handler) }
    @endpoints.push(class_handler.new(name, options, &block))
  end

  def generate_action_json(object, options)
    super
    @endpoints.each do |endpoint|
      endpoint.generate_action_json(object, options)
    end unless options[:embedded]
  end
end
