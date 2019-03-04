class PlateBarcode < ActiveResource::Base
  self.site = configatron.plate_barcode_service
  self.format = ActiveResource::Formats::XmlFormat

  if Rails.env.development?
    MockBarcode = Struct.new(:barcode)

    def self.create
      @barcode ||= Barcode.sanger_code39.where('barcode LIKE "DN%"').order(barcode: :desc).first&.number || 9000000
      MockBarcode.new(@barcode += 1)
    end
  end
end
