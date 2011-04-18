class PlateBarcode < ActiveResource::Base
  self.site = configatron.plate_barcode_service
end
