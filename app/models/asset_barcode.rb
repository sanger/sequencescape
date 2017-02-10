# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

class AssetBarcode < ActiveRecord::Base
  # This class only a concurrency safe counter to generate asset barcode
  def self.new_barcode
    barcode = (AssetBarcode.create!).id

    while Asset.find_by(barcode: barcode.to_s)
      barcode = (AssetBarcode.create!).id
    end

    (barcode).to_s
  end
end
