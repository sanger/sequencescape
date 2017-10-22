# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class TagGroupsTaskTest < TaskTestBase
  class DummyWorkflowController < WorkflowsController
    attr_accessor :batch, :pipeline
  end

  context '#render_tag_groups_task' do
    setup do
      @object = task_instance_for(::Tasks::TagGroupHandler) do
        attr_reader :tag_groups
      end

      @object.render_tag_groups_task(nil, nil)
    end

    should 'not have at least one entry in tag_groups' do
      assert @object.tag_groups.present?
    end
  end

  context 'with a task' do
    setup do
      @task = create :tag_groups_task
      @batch = create :batch
    end

    context '#render_task' do
      should 'call render_tag_groups_task on workflow' do
        @controller = DummyWorkflowController.new
        @user = create :user
        # session[:user] = @user.id
        @controller.batch = @batch
        @workflow = create :lab_workflow_for_pipeline
        params = { batch_id: @batch.id, workflow_id: @workflow.id }
        @task.render_task(@controller, params)
      end
    end

    expected_partial('tag_groups_batches')
  end
end
