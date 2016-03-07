#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2013 Genome Research Ltd.
class PlateBarcode < ActiveResource::Base
  self.site = configatron.plate_barcode_service
  self.format = ActiveResource::Formats::XmlFormat

  if Rails.env == 'development'
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
