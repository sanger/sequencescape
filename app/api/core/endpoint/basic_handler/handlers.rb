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

  def related
    @handlers.map(&:last)
  end

  def actions(object, options)
    @handlers.select do |name, handler|
      handler.is_a?(Core::Endpoint::BasicHandler::Actions::InnerAction)
#      accessible_action?(self, handler, options[:response].request, object)
    end.map do |name, handler|
      handler.send(:actions, object, options)
    end.inject(super) do |actions, subactions|
      actions.merge(subactions)
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

