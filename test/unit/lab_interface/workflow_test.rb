# frozen_string_literal: true

require 'test_helper'

class WorkflowTest < ActiveSupport::TestCase
  context 'A Workflow' do
    should have_many :tasks
    should belong_to :pipeline

    setup do
      pipeline = create :pipeline, name: 'Pipeline for WorkflowTest'
      @workflow = pipeline.workflow
      @workflow.update!(name: 'Workflow for WorkflowTest')

      task = create :task, workflow: @workflow
      create :descriptor, task: task, name: 'prop', value: 'something', key: 'something'
      create :descriptor, task: task, name: 'prop_2', value: 'upstairs', key: 'upstairs'
    end

    subject { @workflow }

    context '#deep_copy' do
      setup do
        @labinterface_workflow_count = Workflow.count
        @task_count = Task.count
        @pipeline_count = Pipeline.count
        @descriptor_count = Descriptor.count
        @workflow.deep_copy
      end

      should 'change Workflow.count by 1' do
        assert_equal 1, Workflow.count - @labinterface_workflow_count, 'Expected Workflow.count to change by 1'
      end

      should 'change Task.count by 1' do
        assert_equal 1, Task.count - @task_count, 'Expected Task.count to change by 1'
      end

      should 'change Pipeline.count by 1' do
        assert_equal 1, Pipeline.count - @pipeline_count, 'Expected Pipeline.count to change by 1'
      end

      should 'change Descriptor.count by 2' do
        assert_equal 2, Descriptor.count - @descriptor_count, 'Expected Descriptor.count to change by 2'
      end

      should 'duplicate workflow' do
        assert_equal 'Workflow for WorkflowTest_dup', Workflow.last.name
      end

      should 'duplicate pipeline' do
        assert_equal 'Pipeline for WorkflowTest_dup', Pipeline.last.name
      end
    end
  end
end
