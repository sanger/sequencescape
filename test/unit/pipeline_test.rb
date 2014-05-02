require "test_helper"

class PipelineTest < ActiveSupport::TestCase
  context "Pipeline" do
    should_have_one  :workflow
    should_have_many :batches, :controls
    should_have_many :request_information_types, :through => :pipeline_request_information_types
    should_have_many :pipeline_request_information_types
    #should_require_attributes :name
    
    context "sequencing_pipeline#read length consistency among batch requests" do
      setup do
        @sample = Factory :sample

        @request_type = Factory :request_type, :name => "sequencing", :target_asset_type => nil
        @submission  = Factory::submission(:request_types => [@request_type].map(&:id), :asset_group_name => 'to avoid asset errors')
        @item = Factory :item, :submission => @submission

        @pipeline = Factory :sequencing_pipeline, :name => "sequencing pipeline", :request_types => [ @request_type ]
        @metadata1 = Factory :request_metadata
        @metadata2 = Factory :request_metadata
        @request1 = Factory(
          :request_without_assets,
          :request_metadata => @metadata1,
          :item         => @item,
          :asset        => Factory(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(:sample => @sample) },
          :target_asset => nil,
          :submission   => @submission,
          :request_type => @request_type,
          :pipeline     => @pipeline
        )

        @request2 = Factory(
          :request_without_assets,
          :request_metadata => @metadata2,
          :item         => @item,
          :asset        => Factory(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(:sample => @sample) },
          :target_asset => nil,
          :submission   => @submission,
          :request_type => @request_type,
          :pipeline     => @pipeline
        )
      end
      
      should "return true if not any request was selected" do
        @batch = Factory :batch
        assert @pipeline.is_read_length_consistent_for_batch?(@batch)
      end
      
      should "return true if the requests don't make use of the read_length attribute" do
        @batch = @pipeline.batches.create!(:requests => [ @request1, @request2 ])
        assert @pipeline.is_read_length_consistent_for_batch?(@batch)
      end
      
      should "check that all the requests has the read_length attribute defined" do
        @request2.request_metadata.read_length = nil        
        @batch = @pipeline.batches.create(:requests => [ @request1, @request2 ])
        assert !@pipeline.is_read_length_consistent_for_batch?(@batch)
      end
      
      should "check that the read_length attribute is the same in all the requests" do
        @request1.request_metadata.read_length = 76
        @request2.request_metadata.read_length = 100
        @batch = @pipeline.batches.create(:requests => [ @request1, @request2 ])
        assert !@pipeline.is_read_length_consistent_for_batch?(@batch)
      end
      
      should "check that other pipelines are not affected by different read_length attributes" do
        @pipeline2 = Factory :pipeline, :name => "other pipeline", :request_types => [ @request_type ]
        @request1 = Factory(
          :request_without_assets,
          :request_metadata => @metadata1,
          :item         => @item,
          :asset        => Factory(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(:sample => @sample) },
          :target_asset => nil,
          :submission   => @submission,
          :request_type => @request_type,
          :pipeline     => @pipeline2
        )

        @request2 = Factory(
          :request_without_assets,
          :request_metadata => @metadata2,
          :item         => @item,
          :asset        => Factory(:empty_sample_tube).tap { |sample_tube| sample_tube.aliquots.create!(:sample => @sample) },
          :target_asset => nil,
          :submission   => @submission,
          :request_type => @request_type,
          :pipeline     => @pipeline2
        )
          
        @request1.request_metadata.read_length = 76
        @request2.request_metadata.read_length = 100
        @batch = @pipeline2.batches.create(:requests => [ @request1, @request2 ])
        assert @pipeline2.is_read_length_consistent_for_batch?(@batch)        
      end
    end
    
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
