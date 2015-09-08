#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2014,2015 Genome Research Ltd.
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
          @purpose.transition_to(@child, state, nil)
        end
      end

      should "fail the pre-pcr plate when failing the entire plate" do
        @grandparent.expects(:transition_to).with('failed', nil,false)
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', nil, nil)
      end

      should "fail the pre-pcr well when failing a well" do
        @child_wells.expects(:located_at).with(['A1']).returns(@child_wells)
        @grandparent.expects(:transition_to).with('failed', ['A1'],false)
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', nil, ['A1'])
      end
    end
  end
end
