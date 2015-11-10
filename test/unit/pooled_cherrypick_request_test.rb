#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require 'test_helper'

class PooledCherrypickRequestTest < ActiveSupport::TestCase

  context "Requests with the same sample and a shared target" do
    setup do
      @well_a    = Factory :well_with_sample_and_without_plate
      @well_b    = Factory :well
      @well_b.aliquots = [@well_a.aliquots.first.clone]
      @target_well = Factory :well
      @study = Factory :study
      @request_a = Factory :pooled_cherrypick_request, :asset=> @well_a, :target_asset => @target_well, :initial_study => @study
      @request_b = Factory :pooled_cherrypick_request, :asset=> @well_b, :target_asset => @target_well, :initial_study => @study
    end

    should 'only transfer one aliquot' do
      @request_a.start!
      @request_b.start!
      assert_equal 1, @target_well.aliquots.count
    end

    context 'when started via a batch' do
      setup do
        @batch = Factory :batch
        @batch.requests << @request_a << @request_b
      end

      should 'behave the same' do
        @batch.start_requests
        assert_equal 1, @target_well.aliquots.count
        assert_equal @well_a.aliquots.first.sample, @target_well.aliquots.first.sample
      end

    end
  end
end
