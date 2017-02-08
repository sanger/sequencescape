# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class LabInterface::WorkflowTest < ActiveSupport::TestCase
  context 'A Workflow' do
    should have_many :tasks
    should belong_to :pipeline

    setup do
      pipeline  = create :pipeline, name: 'Pipeline for LabInterface::WorkflowTest'
      @workflow = pipeline.workflow
      @workflow.update_attributes!(name: 'Workflow for LabInterface::WorkflowTest')

      task = create :task, workflow: @workflow
      create :descriptor, task: task, name: 'prop', value: 'something', key: 'something'
      create :descriptor, task: task, name: 'prop_2', value: 'upstairs', key: 'upstairs'
    end

    subject { @workflow }

    context '#deep_copy' do
      setup do
        @labinterface_workflow_count = LabInterface::Workflow.count
        @task_count = Task.count
        @pipeline_count = Pipeline.count
        @descriptor_count = Descriptor.count
        @workflow.deep_copy
      end

      should 'change LabInterface::Workflow.count by 1' do
        assert_equal 1, LabInterface::Workflow.count - @labinterface_workflow_count, 'Expected LabInterface::Workflow.count to change by 1'
      end

       should 'change Task.count by 1' do
         assert_equal 1,  Task.count - @task_count, 'Expected Task.count to change by 1'
       end

       should 'change Pipeline.count by 1' do
         assert_equal 1,  Pipeline.count - @pipeline_count, 'Expected Pipeline.count to change by 1'
       end

       should 'change Descriptor.count by 2' do
         assert_equal 2,  Descriptor.count - @descriptor_count, 'Expected Descriptor.count to change by 2'
       end

      should 'duplicate workflow' do
        assert_equal 'Workflow for LabInterface::WorkflowTest_dup', LabInterface::Workflow.last.name
      end

      should 'duplicate pipeline' do
        assert_equal 'Pipeline for LabInterface::WorkflowTest_dup', Pipeline.last.name
      end
    end
  end
end
