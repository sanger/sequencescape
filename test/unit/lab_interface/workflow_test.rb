require "test_helper"

class LabInterface::WorkflowTest < ActiveSupport::TestCase
  context "A Workflow" do
    should_have_many :tasks
    should_belong_to :pipeline

    setup do
      pipeline  = Factory :pipeline, :name => "Pipeline for LabInterface::WorkflowTest"
      @workflow = pipeline.workflow
      @workflow.update_attributes!(:name => 'Workflow for LabInterface::WorkflowTest')

      task      = Factory :task, :workflow => @workflow
      Factory :descriptor, :task => task, :name => "prop", :value => "something", :key => "something"
      Factory :descriptor, :task => task, :name => "prop_2", :value => "upstairs", :key => "upstairs"
    end

    subject { @workflow }

    context "#deep_copy" do
      setup do
        @workflow.deep_copy
      end

      should_change("LabInterface::Workflow.count", :by => 1) { LabInterface::Workflow.count }

      should_change("Task.count", :by => 1) { Task.count }

      should_change("Pipeline.count", :by => 1) { Pipeline.count }

      should_change("Descriptor.count", :by => 2) { Descriptor.count }

      should "duplicate workflow" do
        assert_equal "Workflow for LabInterface::WorkflowTest_dup", LabInterface::Workflow.last.name
      end

      should "duplicate pipeline" do
        assert_equal "Pipeline for LabInterface::WorkflowTest_dup", Pipeline.last.name
      end
    end
  end
end
