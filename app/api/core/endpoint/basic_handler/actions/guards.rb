# frozen_string_literal: true
module Core::Endpoint::BasicHandler::Actions::Guards # rubocop:todo Style/Documentation
  class Guard # rubocop:todo Style/Documentation
    def initialize(method = nil, &block) # rubocop:todo Metrics/MethodLength
      if method.present?
        line = __LINE__ + 1
        singleton_class.class_eval(
          "
          def execute(object)
            object.#{method}
          end
        ",
          __FILE__,
          line
        )
      elsif block
        singleton_class.send(:define_method, :execute, &block)
      else
        raise StandardError, 'Either method name or block is required for guards'
      end
    end
  end

  class GuardChain # rubocop:todo Style/Documentation
    def initialize
      @guards = []
    end

    delegate :push, to: :@guards

    def execute(object)
      return true if @guards.empty?

      @guards.all? { |guard| guard.execute(object) }
    end
  end

  class GuardProxy < ActiveSupport::ProxyObject # rubocop:todo Style/Documentation
    def initialize(request, object)
      @request, @object = request, object
    end

    def respond_to?(method, private_methods = false)
      super || @object.respond_to?(method, private_methods)
    end

    def method_missing(name, *args, &block)
      @object.send(name, *args, &block)
    end
    protected :method_missing
  end

  def check_authorisation!(*args)
    accessible_action?(*args) or
      raise ::Core::Service::UnsupportedAction, 'requested action is not supported on this resource'
  end
  private :check_authorisation!

  def accessible_action?(_handler, action, request, object)
    guard_for(action).execute(GuardProxy.new(request, object))
  end
  private :accessible_action?

  def action_guard(name, method_name = nil, &block)
    guard_for(name).push(Guard.new(method_name, &block))
  end

  def guard_for(name)
    @guards ||= Hash.new { |h, k| h[k] = GuardChain.new }
    @guards[name.to_sym]
  end
  private :guard_for
end
