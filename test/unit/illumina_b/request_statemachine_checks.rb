# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015,2016 Genome Research Ltd.

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
            @request = target.new(request_purpose: :standard, target_asset: create(:well))
            @request.stubs(:perform_transfer_of_contents).returns(true)
          end

          acceptable_states.map(&:to_s).each do |state|
            should "transition from #{state}" do
              @request.state = state
              @request.send(:"#{name}")
            end
          end

          (target.aasm.states.map(&:name).map(&:to_s) - acceptable_states.map(&:to_s)).each do |state|
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
