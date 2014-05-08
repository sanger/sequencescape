module QcableStatemachineChecks
  class StatemachineHelper
    def initialize(owner, target, &block)
      @owner, @target = owner, target
      instance_eval(&block)
    end

    def check_event(name, options)
      target = @target
      acceptable_states = options[:from]
      end_state         = options[:to]

      @owner.instance_eval do
        context "##{name}" do
          setup do
            lot = mock('lot')
            template = mock('template')
            template.stubs(:stamp_to)
            lot.stubs(:template).returns(template)
            @qcable = target.new
            @qcable.stubs(:lot).returns(lot)
          end

          acceptable_states.map(&:to_s).each do |state|
            should "transition from #{state} to #{end_state.to_s}" do
              @qcable.state = state
              @qcable.send(:"#{name}")
              assert_equal end_state.to_s, @qcable.state
            end
          end

          (target.aasm_states.map(&:name).map(&:to_s) - acceptable_states.map(&:to_s)).each do |state|
            should "not transition from #{state}" do
              @qcable.state = state
              assert_raises(AASM::InvalidTransition) { @qcable.send(:"#{name}") }
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
