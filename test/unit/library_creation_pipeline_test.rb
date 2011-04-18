require "test_helper"

class LibraryCreationPipelineTest < ActiveSupport::TestCase
  context "Pipeline" do
    setup do
      @pipeline = Factory :library_creation_pipeline, :name => "Library creation pipeline"
    end

    should "return true for library_creation?" do
      assert @pipeline.library_creation?
    end

    should "return false for genotyping?" do
      assert ! @pipeline.genotyping?
    end

    should "return false for pulldown?" do
      assert ! @pipeline.pulldown?
    end

    should "return false for prints_a_worksheet_per_task?" do
      assert ! @pipeline.prints_a_worksheet_per_task?
    end

    context "#create_batch_from_plate(assets)" do

    end
  end
end
