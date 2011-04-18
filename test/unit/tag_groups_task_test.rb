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
    end

    context '#render_task' do
      should 'call render_tag_groups_task on workflow' do
        @workflow = mock('workflow')
        @workflow.expects(:render_tag_groups_task).with(@task, :params).once
        @task.render_task(@workflow, :params)
      end
    end

    expected_partial('tag_groups_batches')
  end
end
