# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015,2016 Genome Research Ltd.

require File.dirname(__FILE__) + '/../../test_helper'

class ProductCriteriaBasicTest < ActiveSupport::TestCase
  context 'a configured criteria' do
    setup do
      @params = {
        concentration: { greater_than: 5 },
        total_micrograms: { greater_than: 10 },
        current_volume: { greater_than: 8, less_than: 2000 },
        gel_pass: { not_equal: 'degraded' },
        conflicting_gender_markers: { less_than: 1 }
      }
    end

    context 'with a bad well' do
      setup do
        @well_attribute = create :well_attribute, concentration: 1, current_volume: 30000, gel_pass: 'OKAY', gender_markers: ['M', 'M', 'U']
        @well = create :well, well_attribute: @well_attribute
        @sample = create :sample, sample_metadata_attributes: { gender: 'female' }
        @well.samples << @sample
        @criteria = ProductCriteria::Basic.new(@params, @well)
      end

      should '#passed? should return false' do
        assert_equal 'failed', @criteria.qc_decision, 'Well passed when it should have failed'
        assert_equal ['Concentration too low', 'Current volume too high', 'Conflicting gender markers too high'], @criteria.comment
      end

      should 'store all values' do
        expected_hash = {
          concentration: 1,
          current_volume: 30000,
          total_micrograms: 30,
          gel_pass: 'OKAY',
          conflicting_gender_markers: 2
        }
        assert_equal expected_hash, @criteria.values
      end
    end

    context 'with a good well' do
      setup do
        @well_attribute = create :well_attribute, concentration: 800, current_volume: 100, gel_pass: 'OKAY', gender_markers: ['M', 'M', 'U']
        @well = create :well, well_attribute: @well_attribute
        @sample = create :sample, sample_metadata_attributes: { gender: 'male' }
        @well.samples << @sample
        @criteria = ProductCriteria::Basic.new(@params, @well)
      end

      should '#pass? should return false' do
        assert_equal [], @criteria.comment
        assert_equal 'passed', @criteria.qc_decision, 'Well failed when it should have passed'
      end

      should 'store all values' do
        expected_hash = {
          concentration: 800,
          current_volume: 100,
          total_micrograms: 80,
          gel_pass: 'OKAY',
          conflicting_gender_markers: 0
        }
        assert_equal expected_hash, @criteria.values
      end
    end
  end
end
