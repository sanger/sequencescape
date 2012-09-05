require "test_helper"

class DummyWorkflowController < WorkflowsController
  attr_accessor :potential_plate_purposes
  attr_accessor :batch
  attr_accessor :flash

  def initialize
    @flash = {}
  end
end

class AssignPlatePurposeHandlerTest < ActiveSupport::TestCase
  context "AssignPlatePurposeHandler" do
    setup do
      @workflows_controller = DummyWorkflowController.new
      @task                 = Factory :assign_plate_purpose_task
      @params               = "UNUSED_PARAMS"
    end

    context "#do_assign_plate_purpose_task" do
      setup do
        @params = {:assign_plate_purpose_task => {:plate_purpose_id => 1}, :batch_id => 1}
        @plate_purpose = 'A_PLATE_PURPOSE_INSTANCE'
        @workflows_controller.batch = mock("Batch")
      end
      context "when @batch has no output plates" do
        setup do
          @workflows_controller.batch.expects(:output_plates).returns([])
          @workflows_controller.batch.expects(:save!).never
          @return_value = @workflows_controller.do_assign_plate_purpose_task(@task,@params)
        end
        should "not try to save the batch but instead return false" do
          assert_equal false, @return_value
        end

        should "set a flash[:error] message" do
          assert_not_nil @workflows_controller.flash[:error]
        end
      end

      context "when @batch has output plates, assign the selected plate_purpose_id to all of @batch's output plates and" do
        setup do
          PlatePurpose.expects(:find).with(1).returns(@plate_purpose)
          @workflows_controller.batch.expects(:output_plates).returns(['A_PLATE_INSTANCE'])
          @workflows_controller.batch.expects(:set_output_plate_purpose).with(@plate_purpose)
          @workflows_controller.batch.expects(:save!).returns(true)
          @return_value = @workflows_controller.do_assign_plate_purpose_task(@task,@params)
        end

        should "return true." do
          assert_equal true, @return_value
        end

        should "set a flash[:notice] for success" do
          assert_not_nil @workflows_controller.flash[:notice]
        end
      end
    end

  end
end
