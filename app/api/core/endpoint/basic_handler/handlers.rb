module Core::Endpoint::BasicHandler::Handlers
  # Handler that behaves like it never deals with any URLs
  NullHandler = Object.new.tap do |handler|
    [ :create, :read, :update, :delete ].each do |action|
      eval(%Q{
        def handler.#{action}(*args, &block)
          raise ::Core::Service::UnsupportedAction
        end
      })
    end
  end

  def initialize
    super
    @handlers = {}
  end

  def generate_action_json(object, options)
    super

    includes = options.fetch(:include, @handlers.keys).map(&:to_sym)
    @handlers.select do |key, _|
      includes.include?(key)
    end.each do |_, handler|
      handler.generate_action_json(object, options.merge(:embedded => true))
    end
  end

  def register_handler(segment, handler)
    @handlers[segment.to_sym] = handler
  end
  private :register_handler

  def handler_for(segment)
    return self if segment.nil?
    _handler_for(segment) || NullHandler
  end
  private :handler_for

  def _handler_for(segment)
    @handlers[segment.to_sym]
  end
  private :_handler_for
end

