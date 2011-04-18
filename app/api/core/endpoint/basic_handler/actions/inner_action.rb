module Core::Endpoint::BasicHandler::Actions::InnerAction
  def initialize(name, options, &block)
    raise StandardError, "Cannot declare inner action #{name.inspect} without a block" unless block_given?

    super() { }
    @options, @handler = options, block
    action(name, options)
  end

  def as_json(options = {})
    json = super
    @options.key?(:json) ? { @options[:json].to_s => json } : json
  end

  def declare_action(name, options)
    line = __LINE__ + 1
    singleton_class.class_eval(%Q{
      def _#{name}(request, response)
        object = @handler.call(request, response)
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
