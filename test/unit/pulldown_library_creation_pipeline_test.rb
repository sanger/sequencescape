require "test_helper"

class PulldownLibraryCreationPipelineTest < ActiveSupport::TestCase
  context "Pipeline" do
    setup do
      @pipeline = Factory :pulldown_library_creation_pipeline, :name => "Pulldown Library creation pipeline"
    end

    should "return true for library_creation?" do
      assert @pipeline.library_creation?
    end

    should "return false for genotyping?" do
      assert ! @pipeline.genotyping?
    end

    should "return true for pulldown?" do
      assert @pipeline.pulldown?
    end

    should "return true for prints_a_worksheet_per_task?" do
      assert @pipeline.prints_a_worksheet_per_task?
    end
  end
end
