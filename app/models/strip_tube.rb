#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
##
# StripTubes can be thought of as long skinny plates.
# Unlike normal plates they can be kept in a rack.
# Strip tubes don't get a barcode assigned upfront.
class StripTube < Plate
  contained_by :asset_rack

  self.prefix = 'LS'

  # Until we no how barcodes are going to work, we'll just override this
  def self.create_with_barcode!(*args, &block)
    attributes = args.extract_options!
    barcode    = args.first || attributes[:barcode]
    create!(attributes.merge(:barcode => barcode), &block)
  end
end
