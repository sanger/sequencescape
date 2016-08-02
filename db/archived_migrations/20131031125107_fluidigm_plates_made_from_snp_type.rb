#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class FluidigmPlatesMadeFromSnpType < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by_key('pick_to_fluidigm')
      rt.acceptable_plate_purposes.clear
      rt.acceptable_plate_purposes << PlatePurpose.find_by_name('SNP Type')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      rt = RequestType.find_by_key('pick_to_fluidigm')
      rt.acceptable_plate_purposes.clear
      rt.acceptable_plate_purposes << PlatePurpose.find_by_name('STA2')
    end
  end
end
