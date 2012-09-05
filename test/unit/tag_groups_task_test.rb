require "test_helper"

class TagGroupsTaskTest < TaskTestBase
  context '#render_tag_groups_task' do
    setup do

      @object = task_instance_for(::Tasks::TagGroupHandler) do
        attr_reader :tag_groups
      end

      @object.render_tag_groups_task(nil, nil)
    end

    should "not have at least one entry in tag_groups" do
      assert 'tag_groups empty', !@object.tag_groups.empty?
    end

    should "assign tag_groups" do
      assert_equal @object.tag_groups, TagGroup.all
    end
  end

  context 'with a task' do
    setup do
      @task = Factory :tag_groups_task
      @batch = Factory :batch
    end

    context '#render_task' do
      should 'call render_tag_groups_task on workflow' do
        @controller  = WorkflowsController.new
        @user = Factory :user
        @controller.stubs(:current_user).returns(@user)
        @workflow = Factory :lab_workflow_for_pipeline
        params = {:batch_id => @batch.id, :workflow_id => @workflow.id}
        @task.render_task(@controller, params)
      end
    end

    expected_partial('tag_groups_batches')
  end
end
