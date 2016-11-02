#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require "test_helper"

class OrderTest < ActiveSupport::TestCase

  attr_reader :study, :asset, :project

  def setup
    @study =  create :study, state: 'pending'
    @project =  create :project
    @asset = create :empty_sample_tube
  end

  test "order should not be valid if study is not active" do
    order = build :order,  study: study, assets: [asset], project: project
    refute order.valid?
  end

  test "order should be valid if study is active on create" do
    study.activate!
    order = create :order,  study: study, assets: [asset], project: project
    assert order.valid?
    study.deactivate!
    new_asset = create :empty_sample_tube
    order.assets << new_asset
    assert order.valid?
  end

end