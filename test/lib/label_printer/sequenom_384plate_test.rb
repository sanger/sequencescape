require 'test_helper'
require_relative 'shared_tests'

class Sequenom384PlateTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedPlateTests

  attr_reader :plate_label, :label, :plate1, :purpose, :barcode1, :top, :bottom

  def setup
    @barcode1 = '7777'
    @plate1 = create :sequenom_qc_plate, barcode: barcode1, name: 'QC134443_9168137_163993_160200_20160617'
    @top = '134443  9168137'
    @bottom = '163993  160200 '
    options = { plates: [plate1], count: 1 }
    @purpose = 'Sequenom'
    @plate_label = LabelPrinter::Label::Sequenom384Plate.new(options)
    @label = { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
               bottom_left: (plate1.sanger_human_barcode).to_s,
               top_right: (top).to_s,
               bottom_right: (bottom).to_s,
               barcode: (plate1.ean13_barcode).to_s }
  end

  test 'should have assets' do
    assert plate_label.assets
  end

  test 'should return the right values' do
    assert_equal (top).to_s, plate_label.top_right(plate1)
    assert_equal (bottom).to_s, plate_label.bottom_right(plate1)
    refute plate_label.top_far_right(plate1)
  end
end
