# frozen_string_literal: true

require 'test_helper'
require 'timecop'

class SampleTubeTest < ActiveSupport::TestCase
  context 'A Sample tube' do
    setup { AssetBarcode.expects(:new_barcode).returns(generate(:barcode_number)) }

    should 'use the AssetBarcode service' do
      SampleTube.create!
    end
  end

  context 'can be rendered as a stock resource' do
    setup do
      Timecop.freeze(DateTime.parse('2012-03-11 10:22:42')) do
        @sample_tube = create(:empty_sample_tube, barcode: '12345')
        @study = create(:study)
        @sample = create(:sample)
        @aliquot = create(:aliquot, study: @study, sample: @sample, receptacle: @sample_tube)
        @messenger = @sample_tube.register_stock!
      end
    end

    should 'render what we expect' do
      assert_equal(
        {
          'lims' => 'SQSCP',
          'stock_resource' => {
            'created_at' => '2012-03-11T10:22:42+00:00',
            'updated_at' => '2012-03-11T10:22:42+00:00',
            'samples' => [{ 'sample_uuid' => @sample.uuid, 'study_uuid' => @study.uuid }],
            'stock_resource_id' => @sample_tube.receptacle.id,
            'stock_resource_uuid' => @sample_tube.receptacle.uuid,
            'machine_barcode' => '3980012345764',
            'human_barcode' => 'NT12345L',
            'labware_type' => 'tube',
            'labware_coordinate' => nil
          }
        },
        JSON.parse(@messenger.to_json)
      )
    end
  end
end
