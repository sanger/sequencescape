class PlateBarcode < ActiveResource::Base
  self.site = configatron.plate_barcode_service

 if RAILS_ENV == 'development'
   def self.create
     if @barcode.nil?
       @barcode = Asset.first(
         :conditions => 'barcode is not null and barcode!="9999999" and length(barcode)=7',
         :order => 'barcode desc'
       ).try(:barcode).to_i

       @barcode = 9000000 if @barcode.zero?
     end

     OpenStruct.new(:barcode => (@barcode += 1))
   end
 end

end
