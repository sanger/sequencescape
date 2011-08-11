require "test_helper"

class AliquotTest < ActiveSupport::TestCase
  context "#match" do
    setup do
      @tag1 = Factory :tag
      @tag2 = Factory :tag
      @sample1 = Factory :sample
      @sample2 = Factory :sample
    end

    should "match aliquots with same tags " do
      assert Aliquot.new(:tag => @tag1) =~ Aliquot.new(:tag => @tag1)
    end
    should "not match aliquots with different tags " do
      assert Aliquot.new(:tag => @tag1) !~ Aliquot.new(:tag => @tag2)
    end

    should " match aliquots with missing tags " do
      assert Aliquot.new(:tag => @tag1) =~ Aliquot.new()
    end

    should "not match aliquots with different samples" do
      assert Aliquot.new(:tag => @tag1, :sample => @sample1) !~ Aliquot.new(:tag => @tag1, :sample => @sample2)
    end


  end

end
