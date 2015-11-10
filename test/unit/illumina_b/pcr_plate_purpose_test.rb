#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2014,2015 Genome Research Ltd.
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
          @parent.expects(:transition_to).with(parent_state, nil, nil)
          @purpose.expects(:default_transition_to).with(@child, child_state, nil, nil, false)
          @purpose.transition_to(@child, child_state, nil)
        end
      end

      ['passed', 'failed', 'cancelled'].each do |state|
        should "not alter parent plate when transitioning to #{state}" do
          @purpose.expects(:default_transition_to).with(@child, state, nil, nil, false)
          @purpose.transition_to(@child, state, nil)
        end
      end
    end
  end
end
