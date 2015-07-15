#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2015 Genome Research Ltd.
require "test_helper"

class AliquotTest < ActiveSupport::TestCase
  context "#match" do
    setup do
      @tag1 = Factory :tag
      @tag2 = Factory :tag

      @sample1 = Factory :sample
      @sample2 = Factory :sample

      @asset = Factory :empty_sample_tube

    end

    should "match aliquots with same tags and tag2s" do
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1) =~ Aliquot.new(:tag => @tag1, :tag2 => @tag1)
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1).matches?(Aliquot.new(:tag => @tag1, :tag2 => @tag1))
    end

    should "not match aliquots with different tags" do
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1) !~ Aliquot.new(:tag => @tag2, :tag2 => @tag1)
      assert ! Aliquot.new(:tag => @tag1, :tag2 => @tag1).matches?(Aliquot.new(:tag => @tag2, :tag2 => @tag1))
    end

    should "not match aliquots with different tag 2" do
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1) !~ Aliquot.new(:tag => @tag1, :tag2 => @tag2)
      assert ! Aliquot.new(:tag => @tag1, :tag2 => @tag1).matches?(Aliquot.new(:tag => @tag1, :tag2 => @tag2))
    end

    should " match aliquots with missing tags " do
      assert Aliquot.new(:tag => @tag1) =~ Aliquot.new()
      assert Aliquot.new(:tag => @tag1).matches?(Aliquot.new())
    end

    should " match aliquots with missing tag 2 " do
      assert Aliquot.new(:tag2 => @tag1) =~ Aliquot.new()
      assert Aliquot.new(:tag2 => @tag1).matches?(Aliquot.new())
    end

    should " match aliquots with missing tags but present tag 2s " do
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1) =~ Aliquot.new(:tag2 => @tag1)
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1).matches?(Aliquot.new(:tag2 => @tag1))
    end

    should " match aliquots with missing tag 2s but present tags " do
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1) =~ Aliquot.new(:tag => @tag1)
      assert Aliquot.new(:tag => @tag1, :tag2 => @tag1).matches?(Aliquot.new(:tag => @tag1))
    end

    should "not match aliquots with different samples" do
      assert Aliquot.new(:tag => @tag1, :sample => @sample1) !~ Aliquot.new(:tag => @tag1, :sample => @sample2)
      assert ! Aliquot.new(:tag => @tag1, :sample => @sample1).matches?(Aliquot.new(:tag => @tag1, :sample => @sample2))
    end

    should "allow mixing different tags with no tag2" do
      @asset.aliquots << Aliquot.new(:tag => @tag1, :sample=>@sample1) << Aliquot.new(:tag => @tag2, :sample=>@sample2)
      @asset.save!
    end

    should "allow mixing different tags with a tag 2" do
      @asset.aliquots << Aliquot.new(:tag => @tag1, :tag2 => @tag1, :sample=>@sample1) << Aliquot.new(:tag => @tag2, :tag2 => @tag1, :sample=>@sample2)
      @asset.save!
    end

    should "allow mixing same tags with a different tag 2" do
      @asset.aliquots << Aliquot.new(:tag => @tag1, :tag2 => @tag1, :sample=>@sample1) << Aliquot.new(:tag => @tag1, :tag2 => @tag2, :sample=>@sample2)
      @asset.save!
    end

    should "disallow mixing same tags with no tag 2" do
      assert_raise ActiveRecord::RecordInvalid do
        @asset.aliquots << Aliquot.new(:tag => @tag1, :sample=>@sample1) << Aliquot.new(:tag => @tag1, :sample=>@sample2)
        @asset.save!
      end
    end

    should "disallow mixing same tags with same tag 2" do
      assert_raise ActiveRecord::RecordInvalid do
        @asset.aliquots << Aliquot.new(:tag => @tag1, :tag2 => @tag2, :sample=>@sample1) << Aliquot.new(:tag => @tag1, :tag2 => @tag2, :sample=>@sample2)
        @asset.save!
      end
    end


  end

end
