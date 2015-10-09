#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require File.dirname(__FILE__) + '/../../test_helper'

class ProductCriteriaBasicTest < ActiveSupport::TestCase

  context "a configured criteria" do

    setup do
      @params = {
        :concentration    => {:greater_than => 5 },
        :total_micrograms => {:greater_than => 10 },
        :measured_volume  => {:greater_than => 8, :less_than => 2000 },
        :gel_pass         => {}
      }
    end

    context "with a bad well" do
      setup do
        @well_attribute = Factory :well_attribute, :concentration => 1, :measured_volume => 30000, :gel_pass => true
        @well = Factory :well, :well_attribute => @well_attribute
        @criteria = ProductCriteria::Basic.new(@params,@well)
      end

      should '#passed? should return false' do
        assert !@criteria.passed?, 'Well passed when it should have failed'
        assert_equal ['Concentration too low','Measured volume too high'], @criteria.errors
      end

      should 'store all values' do
        expected_hash = {
          :concentration => 1,
          :measured_volume => 30000,
          :total_micrograms => 30,
          :gel_pass => true
        }
        assert_equal expected_hash, @criteria.values
      end
    end

    context "with a good well" do
      setup do
        @well_attribute = Factory :well_attribute, :concentration => 800, :measured_volume => 100, :gel_pass => true
        @well = Factory :well, :well_attribute => @well_attribute
        @criteria = ProductCriteria::Basic.new(@params,@well)
      end

      should '#pass? should return false' do
        assert_equal [], @criteria.errors
        assert @criteria.passed?, 'Well failed when it should have passed'
      end

      should 'store all values' do
        expected_hash = {
          :concentration => 800,
          :measured_volume => 100,
          :total_micrograms => 80,
          :gel_pass => true
        }
        assert_equal expected_hash, @criteria.values
      end
    end
  end
end
