# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

class PooledCherrypickRequestTest < ActiveSupport::TestCase
  context 'Requests with the same sample and a shared target' do
    setup do
      @study = create :study

      @well_a = create :well
      @well_b = create :well

      @a1 = create :aliquot, receptacle: @well_a, study: @study
      @a2 = create :aliquot, sample: @a1.sample, study: @study, project: @a1.project, receptacle: @well_b, tag: @a1.tag, tag2: @a1.tag2

      @target_well = create :well

      @request_a = create :pooled_cherrypick_request, asset: @well_a, target_asset: @target_well, initial_study: @study
      @request_b = create :pooled_cherrypick_request, asset: @well_b, target_asset: @target_well, initial_study: @study
    end

    should 'only transfer one aliquot' do
      @request_a.start!
      @request_b.start!
      assert_equal 1, @target_well.aliquots.count
    end

    context 'when started via a batch' do
      setup do
        @batch = create :batch
        @batch.requests << @request_a << @request_b
      end

      should 'behave the same' do
        @batch.start_requests
        assert_equal 1, @target_well.aliquots.count
        expected_sample = @well_a.aliquots.first.sample
        assert_equal expected_sample, @target_well.aliquots.first.sample
      end
    end
  end
end
