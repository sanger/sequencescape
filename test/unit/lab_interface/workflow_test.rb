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
  end
end
