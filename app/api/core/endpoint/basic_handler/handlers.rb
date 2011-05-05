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

  def as_json(options = {})
    super.tap do |json|
      segments = @handlers.keys
      segments = segments && options[:include].map(&:to_sym) if options.key?(:include)

      # I have no idea why I put 'unless options[:embedded]' on this as it doesn't seem to
      # do anything other than stop stuff working!
      segments.each do |segment|
        json.deep_merge!(@handlers[segment].as_json(options.merge(:embedded => true)))
      end
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

