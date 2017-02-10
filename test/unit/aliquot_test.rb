# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015,2016 Genome Research Ltd.

require 'test_helper'

class AliquotTest < ActiveSupport::TestCase
  context '#match' do
    setup do
      @tag1 = create :tag
      @tag2 = create :tag
      @sample1 = create :sample
      @sample2 = create :sample

      @asset = create :empty_sample_tube
    end

    should 'match aliquots with same tags and tag2s' do
      assert Aliquot.new(tag: @tag1, tag2: @tag1) =~ Aliquot.new(tag: @tag1, tag2: @tag1)
      assert Aliquot.new(tag: @tag1, tag2: @tag1).matches?(Aliquot.new(tag: @tag1, tag2: @tag1))
    end

    should 'not match aliquots with different tags' do
      assert Aliquot.new(tag: @tag1, tag2: @tag1) !~ Aliquot.new(tag: @tag2, tag2: @tag1)
      assert !Aliquot.new(tag: @tag1, tag2: @tag1).matches?(Aliquot.new(tag: @tag2, tag2: @tag1))
    end

    should 'not match aliquots with different tag 2' do
      assert Aliquot.new(tag: @tag1, tag2: @tag1) !~ Aliquot.new(tag: @tag1, tag2: @tag2)
      assert !Aliquot.new(tag: @tag1, tag2: @tag1).matches?(Aliquot.new(tag: @tag1, tag2: @tag2))
    end

    should ' match aliquots with missing tags ' do
      assert Aliquot.new(tag: @tag1) =~ Aliquot.new
      assert Aliquot.new(tag: @tag1).matches?(Aliquot.new)
    end

    should ' match aliquots with missing tag 2 ' do
      assert Aliquot.new(tag2: @tag1) =~ Aliquot.new
      assert Aliquot.new(tag2: @tag1).matches?(Aliquot.new)
    end

    should ' match aliquots with missing tags but present tag 2s ' do
      assert Aliquot.new(tag: @tag1, tag2: @tag1) =~ Aliquot.new(tag2: @tag1)
      assert Aliquot.new(tag: @tag1, tag2: @tag1).matches?(Aliquot.new(tag2: @tag1))
    end

    should ' match aliquots with missing tag 2s but present tags ' do
      assert Aliquot.new(tag: @tag1, tag2: @tag1) =~ Aliquot.new(tag: @tag1)
      assert Aliquot.new(tag: @tag1, tag2: @tag1).matches?(Aliquot.new(tag: @tag1))
    end

    should 'not match aliquots with different samples' do
      assert Aliquot.new(tag: @tag1, sample: @sample1) !~ Aliquot.new(tag: @tag1, sample: @sample2)
      assert !Aliquot.new(tag: @tag1, sample: @sample1).matches?(Aliquot.new(tag: @tag1, sample: @sample2))
    end

    should 'allow mixing different tags with no tag2' do
      @asset.aliquots << Aliquot.new(tag: @tag1, sample: @sample1) << Aliquot.new(tag: @tag2, sample: @sample2)
      @asset.save!
    end

    should 'allow mixing different tags with a tag 2' do
      @asset.aliquots << Aliquot.new(tag: @tag1, tag2: @tag1, sample: @sample1) << Aliquot.new(tag: @tag2, tag2: @tag1, sample: @sample2)
      @asset.save!
    end

    should 'allow mixing same tags with a different tag 2' do
      @asset.aliquots << Aliquot.new(tag: @tag1, tag2: @tag1, sample: @sample1) << Aliquot.new(tag: @tag1, tag2: @tag2, sample: @sample2)
      @asset.save!
    end
  end
end
