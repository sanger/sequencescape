# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'
require 'timecop'

class SampleTubeTest < ActiveSupport::TestCase
  context 'A Sample tube' do
    setup do
      AssetBarcode.expects :new_barcode
    end

    should 'use the AssetBarcode service' do
      SampleTube.create!
    end
  end

  context 'can be rendered as a stock resource' do
    setup do
      Timecop.freeze(DateTime.parse('2012-03-11 10:22:42')) do
        @sample_tube = create :empty_sample_tube, barcode: '12345'
        @study = create :study
        @sample = create :sample
        @aliquot = create :aliquot, study: @study, sample: @sample, receptacle: @sample_tube
        @messenger = Messenger.new(target: @sample_tube, template: 'TubeStockResourceIO', root: 'stock_resource')
      end
    end

    should 'render what we expect' do
      assert_equal({
                     'lims' => 'SQSCP',
                     'stock_resource' => {
                       'created_at' => '2012-03-11T10:22:42+00:00',
                       'updated_at' => '2012-03-11T10:22:42+00:00',
                       'samples' => [
                         'sample_uuid' => @sample.uuid,
                         'study_uuid' => @study.uuid
                       ],
                       'stock_resource_id' => @sample_tube.id,
                       'stock_resource_uuid' => @sample_tube.uuid,
                       'machine_barcode' => '3980012345764',
                       'human_barcode' => 'NT12345L',
                       'labware_type' => 'tube'
                     }
                   }, JSON.parse(@messenger.to_json))
    end

    should 'allow registration of messengers' do
      @messenger_count = Messenger.count
      @sample_tube.register_stock!
      assert_equal 1, Messenger.count - @messenger_count
      assert_equal 'stock_resource', Messenger.last.root
      assert_equal 'TubeStockResourceIO', Messenger.last.template
      assert_equal @sample_tube, Messenger.last.target
    end
  end
end
