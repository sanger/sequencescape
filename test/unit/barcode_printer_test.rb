require 'test_helper'

class BarcodePrinterTest < ActiveSupport::TestCase

  attr_reader :barcode_printer, :printer_for_384_wells_plate

  def setup
    @barcode_printer = create :barcode_printer
    @printer_for_384_wells_plate = create :barcode_printer, barcode_printer_type_id: 3
  end

  test "should know if it can print on plates with 384 wells" do
    refute barcode_printer.plate384_printer?
    assert printer_for_384_wells_plate.plate384_printer?
  end

end
