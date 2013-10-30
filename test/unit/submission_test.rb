require "test_helper"

class SubmissionTest < ActiveSupport::TestCase

  def orders_compatible?(a, b, key=nil)
    begin
      submission = Submission.new(:user => Factory(:user),:orders => [a,b])
      submission.save!
      true
    rescue ActiveRecord::RecordInvalid => exception
      if key
        !submission.errors[key]
      else
        false
      end
    end
  end

  context "#priority" do

    setup do
      @submission = Submission.new(:user => Factory(:user))
    end

    should "be 0 by default" do
      assert_equal 0, @submission.priority
    end

    should "be changable" do
      @submission.priority = 3
      assert @submission.valid?
      assert_equal 3, @submission.priority
    end

    should "have a maximum of 3" do
      @submission.priority = 4
      assert_equal false, @submission.valid?
    end

  end

  context "#orders compatible" do
    setup do
      @study1 =  Factory :study
      @study2 = Factory :study

      @project =  Factory :project
      @project2 = Factory :project

      @asset1 = Factory :empty_sample_tube
      @asset1.aliquots.create!(:sample => Factory(:sample, :studies => [@study1]))
      @asset2 = Factory :empty_sample_tube
      @asset2.aliquots.create!(:sample => Factory(:sample, :studies => [@study2]))

      @reference_genome1 = Factory :reference_genome, :name => "genome 1"
      @reference_genome2 = Factory :reference_genome, :name => "genome 2"

      @order1 = Factory :order, :study => @study1, :assets => [@asset1], :project => @project
      @order2 = Factory :order,:study => @study2, :assets => [@asset2], :project => @project
    end

    context "with compatible requests" do
      setup do
        @order2.request_types = @order1.request_types
      end

      context "and study with same reference genome" do
        setup do
          @study1.reference_genome = @reference_genome1
          @study2.reference_genome = @reference_genome1
        end

        should "be compatible" do
          assert orders_compatible?(@order1, @order2)
        end
      end
      context "and study with different contaminated human DNA policy" do
        setup do
          @study1.study_metadata.contaminated_human_dna = true
          @study2.study_metadata.contaminated_human_dna = false
        end

        should "be incompatible" do
          assert_equal false, orders_compatible?(@order1, @order2)
        end
      end

      context "and incompatible request options" do
        setup do
          @order1.request_options = {:option => "value"}
        end

        should "be incompatible" do
          assert_equal false, orders_compatible?(@order1, @order2, :request_options)
        end
      end

      context "and different projects" do
        setup do
          @order2.project = @project2
        end

        should "be incompatible" do
          assert_equal false, orders_compatible?(@order1, @order2)
        end
      end

    end
  end
end
