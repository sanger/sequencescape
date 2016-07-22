require 'test_helper'
require_relative 'shared_tests'

class SequenomPlateTest < ActiveSupport::TestCase

  include LabelPrinterTests::SharedPlateTests

  attr_reader :plate_label, :label, :plate1, :purpose, :barcode1, :top, :bottom

  def setup
    @barcode1 = "7777"
    @plate1 = create :sequenom_qc_plate, barcode: barcode1, name: 'QC134443_9168137_163993_160200_20160617'
    @top = "134443  9168137"
    @bottom = "163993  160200 "
    options = {plates: [plate1], count: 1}
    @purpose = "Sequenom"
    @plate_label = LabelPrinter::Label::SequenomPlate.new(options)
    @label = {top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
            bottom_left: "#{plate1.sanger_human_barcode}",
            top_right: "#{top}",
            bottom_right: "#{bottom}",
            top_far_right: "#{purpose}",
            barcode: "#{plate1.ean13_barcode}"}
  end

  test 'should have assets' do
    assert plate_label.assets
  end

  test 'should return the right values' do
    assert_equal "#{top}", plate_label.top_right(plate1)
    assert_equal "#{bottom}", plate_label.bottom_right(plate1)
    assert_equal "#{purpose}", plate_label.top_far_right(plate1)
  end


end