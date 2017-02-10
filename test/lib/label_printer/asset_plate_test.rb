require 'test_helper'
require_relative 'shared_tests'

class AssetPlateTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedPlateTests

  attr_reader :plate_label, :label, :plates, :plate1, :plate2, :barcode1, :prefix, :plate_name

  def setup
    @plate_name = 'Plate name'
    @barcode1 = '11111'
    @prefix = 'DN'
    @plate1 = create :child_plate, barcode: barcode1
    @plate2 = create :child_plate
    @plates = [plate1, plate2]
    @plate_label = LabelPrinter::Label::AssetPlate.new(plates)
    @label = { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
               bottom_left: (plate1.sanger_human_barcode).to_s,
               top_right: "#{prefix} #{barcode1}",
               bottom_right: "#{plate_name} #{barcode1}",
               top_far_right: nil,
               barcode: (plate1.ean13_barcode).to_s }
  end

  test 'should return the right plates' do
    assert_equal plates, plate_label.assets
  end

  test 'should return the correct specific values' do
    assert_equal "#{prefix} #{barcode1}", plate_label.top_right(plate1)
    assert_equal "#{plate_name} #{barcode1}", plate_label.bottom_right(plate1)
  end
end
