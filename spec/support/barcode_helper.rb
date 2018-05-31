module BarcodeHelper
  MockBarcode = Struct.new(:barcode)

  def mock_plate_barcode_service
    @num_barcode = 1000
    allow(PlateBarcode).to receive(:create) do
      @num_barcode += 1
      build(:plate_barcode, barcode: @num_barcode)
    end
  end
end
