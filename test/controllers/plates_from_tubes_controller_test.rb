# frozen_string_literal: true

require 'test_helper'

class PlatesFromTubesControllerTest < ActionController::TestCase
  context 'Plates from Tubes' do
    setup do
      @controller = PlatesFromTubesController.new
      @requeust = ActionController::TestRequest.create(@controller)

      @barcode_printer = create(:barcode_printer)

      PlateBarcode.stubs(:create_barcode).returns(
        build(:plate_barcode, barcode: 'SQPD-1234567'),
        build(:plate_barcode, barcode: 'SQPD-1234568'),
        build(:plate_barcode, barcode: 'SQPD-1234569'),
        build(:plate_barcode, barcode: 'SQPD-1234570'),
        build(:plate_barcode, barcode: 'SQPD-1234571'),
        build(:plate_barcode, barcode: 'SQPD-1234572')
      )

      LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
      LabelPrinter::PmbClient.stubs(:print).returns(200)
    end
  end
end
