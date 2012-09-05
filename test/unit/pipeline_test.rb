require "test_helper"

class PipelineTest < ActiveSupport::TestCase
  context "Pipeline" do
    should_have_one  :workflow
    should_have_many :batches, :controls
    should_have_many :request_information_types, :through => :pipeline_request_information_types
    should_have_many :pipeline_request_information_types
    #should_require_attributes :name

    context "#QC related batches" do
      setup do
        @pipeline_next = Factory :pipeline, :name => "Next pipeline"
        @pipeline = Factory :pipeline, :name => "Normal pipeline", :next_pipeline_id => @pipeline_next.id
        @pipeline_qc_manual = Factory :qc_pipeline, :name => "Manual Quality Control", :next_pipeline_id => @pipeline_next.id
        @pipeline_qc = Factory :qc_pipeline, :name => "quality control", :next_pipeline_id => @pipeline_qc_manual.id, :automated => true

        @batch_pending = Factory :batch, :pipeline => @pipeline, :qc_pipeline_id => @pipeline_qc.id, :state => "released", :qc_state => "qc_pending"
        @batch_completed = Factory :batch, :pipeline => @pipeline, :qc_pipeline_id => @pipeline_qc.id, :state => "released", :qc_state => "qc_manual"
        @batch_completed_pass = Factory :batch, :pipeline => @pipeline, :qc_pipeline_id => @pipeline_qc.id, :state => "released", :qc_state => "qc_completed", :production_state => "pass"
        @batch_completed_fail = Factory :batch, :pipeline => @pipeline, :qc_pipeline_id => @pipeline_qc.id, :state => "released", :qc_state => "qc_completed", :production_state => "fail"
      end

      context "#qc?" do
        should "return true for automated qc pipeline" do
          assert @pipeline_qc.qc?
        end

        should "return true for manual_qc_pipeline" do
          assert @pipeline_qc_manual.qc?
        end

        should "not return true for non qc_pipeline" do
          assert ! @pipeline.qc?
        end
      end

    #   context "#qc_batches_completed" do
    #     should "return both passed and failed batches" do
    #       assert_equal 2, @pipeline_qc.qc_batches_completed.size
    #     end
    #
    #     should "return two batches" do
    #       assert_equal [@batch_completed_pass, @batch_completed_fail].sort{|a,b| a.id <=> b.id }, @pipeline_qc.qc_batches_completed.sort{|a,b| a.id <=> b.id }
    #     end
    #   end
    end
  end
end
