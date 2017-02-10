# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class SampleTubeTest < ActiveSupport::TestCase
  context 'A Sample tube' do
    setup do
      AssetBarcode.expects :new_barcode
    end

    should 'use the AssetBarcode service' do
      SampleTube.create!
    end
  end
end
