require "test_helper"

class SubmissionTest < ActiveSupport::TestCase

  context "#orders compatible" do
    setup do
      @study1 =  Factory :study
      @study2 = Factory :study

      @project =  Factory :project

      @asset1 = Factory :empty_sample_tube
      @asset1.aliquots.create!(:sample => Factory(:sample, :studies => [@study1]))
      @asset2 = Factory :empty_sample_tube
      @asset2.aliquots.create!(:sample => Factory(:sample, :studies => [@study2]))

      @reference_genome1 = Factory :reference_genome, :name => "genome 1"
      @reference_genome2 = Factory :reference_genome, :name => "genome 2"

      @order1 = Factory :order, :study => @study1, :assets => [@asset1]
      @order2 = Factory :order,:study => @study2, :assets => [@asset2]
    end

    context "compatible requests" do
      setup do
        @order2.request_types = @order1.request_types
      end

      context "and study with same reference genome" do
        setup do
          @study1.reference_genome = @reference_genome1
          @study2.reference_genome = @reference_genome2
        end

        should "be compatible" do
          assert Submission.orders_compatible?(@order1, @order2)
        end

        context "and sample with a different reference genome" do
          setup do
            @asset2.aliquots.first.sample.sample_metadata.reference_genome=@reference_genome2
          end
        should "be incompatible" do
          $stop = true
          assert_equal false, Submission.orders_compatible?(@order1, @order2)
        end
        end
      end
      context "and study with different contaminated human DNA policy" do
        setup do
          @study1.study_metadata.contaminated_human_dna = true
          @study2.study_metadata.contaminated_human_dna = false
        end

        should "be incompatible" do
          assert_equal false, Submission.orders_compatible?(@order1, @order2)
        end
      end
    end
  end
end
