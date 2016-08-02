#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddQcableByBarcodeSearch < ActiveRecord::Migration
 def self.up
    Search::FindQcableByBarcode.create!(:name=>'Find qcable by barcode')
  end

  def self.down
    Search.find_by_name('Find qcable by barcode').destroy!
  end
end
