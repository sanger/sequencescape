#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class FluidigmPlatesUseOwnBarcode < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.find_all_by_name(['Fluidigm 96-96','Fluidigm 192-24']).each do |purpose|
        purpose.update_attributes!(:barcode_for_tecan=>'fluidigm_barcode')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_all_by_name(['Fluidigm 96-96','Fluidigm 192-24']).each do |purpose|
        purpose.update_attributes!(:barcode_for_tecan=>'ean13_barcode')
      end
    end
  end
end
