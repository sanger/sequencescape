module Core::Endpoint::BasicHandler::Actions::InnerAction
  def initialize(name, options, &block)
    raise StandardError, "Cannot declare inner action #{name.inspect} without a block" unless block_given?

    super() { }
    @options, @handler = options, block
    action(name, options)
  end

  def separate(_, actions)
    actions[@options[:to].to_s] = lambda do |object, options, stream|
      actions(object, options.merge(:target => object)).map(&stream.method(:attribute))
    end
  end

  def for_json
    nil
  end

  def rooted_json(options, &block)
    return yield(options[:stream]) if @options.key?(:json)
    options[:stream].block(@options[:json].to_s, &block)
  end
  private :rooted_json

  def generate_json_actions(object, options)
    rooted_json(options) do |stream|
      super(object, options.merge(:stream => stream))
    end
  end

  def declare_action(name, options)
    line = __LINE__ + 1
    singleton_class.class_eval(%Q{
      def _#{name}(request, response)
        object = @handler.call(self, request, response)
        yield(owner_for(request, object), object)
      end
    }, __FILE__, line)
  end
  private :declare_action

  def core_path(*args)
    super(@options[:to], *args)
  end
  private :core_path
end
