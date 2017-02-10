# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  attr_reader :study, :asset, :project

  def setup
    @study = create :study, state: 'pending'
    @project = create :project
    @asset = create :empty_sample_tube
  end

  context 'An order' do
    setup do
      @shared_template = 'shared_template'
      @asset_a = create :sample_tube
      @order   = create :order, assets: [@asset_a], template_name: @shared_template
    end

    should 'not detect duplicates when there are none' do
      refute @order.duplicates_within(1.month)
    end

    context 'with the same asset in a different order' do
      setup do
        @other_template = 'other_template'
        @secondary_order = create :order, assets: [@asset_a], template_name: @other_template
      end
      should 'not detect duplicates' do
        refute @order.duplicates_within(1.month)
      end
    end

    context 'with the same sample in a similar order' do
      setup do
        @asset_b = create :sample_tube, sample: @asset_a.samples.first
        @secondary_submission = create :submission
        @secondary_order = create :order, assets: [@asset_b], template_name: @shared_template, submission: @secondary_submission
      end
      should 'detect duplicates' do
        assert @order.duplicates_within(1.month)
      end
      should 'yield the samples, order and submission to a block' do
        yielded = false
        @order.duplicates_within(1.month) do |samples, orders, submissions|
          yielded = true
          assert_equal [@asset_a.samples.first], samples
          assert_equal [@secondary_order], orders
          assert_equal [@secondary_submission], submissions
        end
        assert yielded, 'duplicates_within failed to yield'
      end
    end
  end

  test 'order should not be valid if study is not active' do
    order = build :order, study: study, assets: [asset], project: project
    refute order.valid?
  end

  test 'order should be valid if study is active on create' do
    study.activate!
    order = create :order, study: study, assets: [asset], project: project
    assert order.valid?
    study.deactivate!
    new_asset = create :empty_sample_tube
    order.assets << new_asset
    assert order.valid?
  end
end
