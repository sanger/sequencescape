require 'test_helper'

class TubeTest < ActiveSupport::TestCase
  test '#barcode! should add barcode to a tube' do
    tube = create :sample_tube_without_barcode
    refute tube.barcode
    tube.barcode!
    assert tube.barcode
    barcode = tube.barcode
    tube.barcode!
    assert_equal barcode, tube.barcode
  end
end
