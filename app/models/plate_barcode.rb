# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

class PlateBarcode < ActiveResource::Base
  self.site = configatron.plate_barcode_service
  self.format = ActiveResource::Formats::XmlFormat

  if Rails.env == 'development'
    MockBarcode = Struct.new(:barcode)

    def self.create
      if @barcode.nil?
        @barcode = Asset.where('barcode is not null and barcode!="9999999" and length(barcode)=7')
                        .order('barcode desc').first.try(:barcode).to_i

        @barcode = 9000000 if @barcode.zero?
      end
      MockBarcode.new(@barcode += 1)
    end
  end
end
