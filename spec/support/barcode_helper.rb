# frozen_string_literal: true

module BarcodeHelper
  def mock_plate_barcode_service
    allow(PlateBarcode).to receive(:create) do
      build(:plate_barcode)
    end
  end
end
