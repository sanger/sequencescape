# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2014,2015 Genome Research Ltd.

require 'test_helper'

class IlluminaHtp::FinalPlatePurposeTest < ActiveSupport::TestCase
  context IlluminaHtp::FinalPlatePurpose do
    setup do
      @purpose = IlluminaHtp::FinalPlatePurpose.new
      @purpose.stubs(:assign_library_information_to_wells)
    end

    context '#transition_to' do
      setup do
        @child, @parent, @grandparent, @user = mock('PCR XP'), mock('PCR'), mock('PRE PCR'), mock('user')
        @child.stubs(:parent).returns(@parent)
        @parent.stubs(:parent).returns(@grandparent)

        @child_wells = mock('PCR XP wells')
        @child.stubs(:wells).returns(@child_wells)
      end

      ['passed', 'cancelled'].each do |state|
        should "not alter pre-pcr plate when transitioning entire plate to #{state}" do
          @purpose.expects(:transition_state_requests).with(@child_wells, state)
          @purpose.transition_to(@child, state, @user, nil)
        end
      end

      should 'fail the pre-pcr plate when failing the entire plate' do
        @grandparent.expects(:transition_to).with('failed', @user, nil, false)
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', @user, nil)
      end

      should 'fail the pre-pcr well when failing a well' do
        @child_wells.expects(:located_at).with(['A1']).returns(@child_wells)
        @grandparent.expects(:transition_to).with('failed', @user, ['A1'], false)
        @purpose.expects(:transition_state_requests).with(@child_wells, 'failed')
        @purpose.transition_to(@child, 'failed', @user, ['A1'])
      end
    end
  end
end
