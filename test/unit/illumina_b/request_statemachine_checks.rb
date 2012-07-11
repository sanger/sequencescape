module IlluminaB::RequestStatemachineChecks
  class StatemachineHelper
    def initialize(owner, target, &block)
      @owner, @target = owner, target
      instance_eval(&block)
    end

    def check_event(name, *acceptable_states)
      target = @target

      @owner.instance_eval do
        context "##{name}" do
          setup do
            @request = target.new
            @request.stubs(:perform_transfer_of_contents).returns(true)
          end

          acceptable_states.map(&:to_s).each do |state|
            should "transition from #{state}" do
              @request.state = state
              @request.send(:"#{name}")
            end
          end

          (target.aasm_states.map(&:name).map(&:to_s) - acceptable_states.map(&:to_s)).each do |state|
            should "not transition from #{state}" do
              @request.state = state
              assert_raises(AASM::InvalidTransition) { @request.send(:"#{name}") }
            end
          end
        end
      end
    end
  end

  def state_machine(state_machined_class, &block)
    StatemachineHelper.new(self, state_machined_class, &block)
  end
end
