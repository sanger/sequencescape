require 'test_helper'

class IlluminaB::FinalPlatePurposeTest < ActiveSupport::TestCase
  context IlluminaB::FinalPlatePurpose do
    setup do
      @purpose = IlluminaB::FinalPlatePurpose.new
      @purpose.stubs(:assign_library_information_to_wells)
    end

    context '#transition_to' do
      setup do
        @child, @parent, @grandparent = mock('PCR XP'), mock('PCR'), mock('PRE PCR')
        @child.stubs(:parent).returns(@parent)
        @parent.stubs(:parent).returns(@grandparent)

        @child_wells = mock('PCR XP wells')
        @child.stubs(:wells).returns(@child_wells)
      end

      ['passed', 'cancelled'].each do |state|
        should "not alter pre-pcr plate when transitioning entire plate to #{state}" do
          @purpose.expects(:transition_state_requests).with(@child_wells, state)
          @purpose.transition_to(@child, state)
        end
      end

      should "fail the pre-pcr plate when failing the entire plate" do
        @grandparent.expects(:transition_to).with('failed', nil)
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', nil)
      end

      should "fail the pre-pcr well when failing a well" do
        @child_wells.expects(:located_at).with(['A1']).returns(@child_wells)
        @grandparent.expects(:transition_to).with('failed', ['A1'])
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', ['A1'])
      end
    end
  end
end
