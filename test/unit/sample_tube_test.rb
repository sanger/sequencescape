
require "test_helper"

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
