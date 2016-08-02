#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RemoveRedundantDilutionPlateCreators < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Plate::Creator.find_by_name('Dilution Plates').destroy
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      plate_creator = Plate::Creator.create!(
      :name => 'Dilution Plates',
      :plate_purpose => PlatePurpose.find_by_name('Dilution Plates')
      )
      plate_creator.plate_purposes << PlatePurpose.find_by_name('Working Dilution') << PlatePurpose.find_by_name('Pico Dilution')
    end
  end
end
