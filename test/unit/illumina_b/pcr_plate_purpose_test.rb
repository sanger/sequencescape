require 'test_helper'

class IlluminaB::PcrPlatePurposeTest < ActiveSupport::TestCase
  context IlluminaB::PcrPlatePurpose do
    setup do
      @purpose = IlluminaB::PcrPlatePurpose.new
    end

    context '#transition_to' do
      setup do
        @child, @parent = mock('child plate'), mock('parent plate')
        @child.stubs(:parent).returns(@parent)
      end

      {
        'started_fx' => 'started',
        'started_mj' => 'passed'
      }.each do |child_state, parent_state|
        should "cause parent to transition to #{parent_state} when transitioning to #{child_state}" do
          @parent.expects(:transition_to).with(parent_state, nil)
          @purpose.expects(:default_transition_to).with(@child, child_state, nil)
          @purpose.transition_to(@child, child_state)
        end
      end

      ['passed', 'failed', 'cancelled'].each do |state|
        should "not alter parent plate when transitioning to #{state}" do
          @purpose.expects(:default_transition_to).with(@child, state, nil)
          @purpose.transition_to(@child, state)
        end
      end
    end
  end
end
