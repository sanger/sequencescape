#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
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
