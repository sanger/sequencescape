require "test_helper"

class AssignPlatePurposeTaskTest < ActiveSupport::TestCase
  context "AssignPlatePurposeTask" do
    setup do
      @assign_plate_purpose_task = AssignPlatePurposeTask.new
      @batch = Factory :batch
      @workflows_controller  = WorkflowsController.new
      @workflow = Factory :lab_workflow_for_pipeline
      @user = Factory :user
      @workflows_controller.stubs(:current_user).returns(@user)
      @params = {:batch_id => @batch.id, :workflow_id => @workflow.id}
    end

    context "#plate_purpose_options" do
      should 'return only the cherrypickable plate purposes' do
        assert_equal(PlatePurpose.cherrypickable_as_target.all.map { |p| [p.name, p.id] }.sort, @assign_plate_purpose_task.plate_purpose_options(@batch))
      end
    end

    context "#partial" do
      should "return the name of the partial used to display this task, 'assign_plate_purpose'" do
        assert_equal 'assign_plate_purpose', @assign_plate_purpose_task.partial
      end
    end

    context "#render_task" do
      should "call WorkflowsController#render_assign_plate_purpose_task and return nil." do
        @workflows_controller.expects(:render_assign_plate_purpose_task).once
        assert_nil @assign_plate_purpose_task.render_task(@workflows_controller,@params)
      end
    end

    context "#do_task" do
      should "call WorkflowsController#do_assign_plate_purpose_task and return nil." do
        @workflows_controller.expects(:do_assign_plate_purpose_task).once
        assert_nil @assign_plate_purpose_task.do_task(@workflows_controller,@params)
      end
    end

  end
end
