require 'test_helper'

class TubeTest < ActiveSupport::TestCase
  test '#barcode! should add barcode to a tube' do
    tube = create :tube, primary_barcode: nil
    refute tube.barcode_number
    tube.barcode!
    assert tube.barcode_number
    barcode = tube.barcode_number
    tube.barcode!
    assert_equal barcode, tube.barcode_number
  end
end
