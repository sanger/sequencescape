#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.

class AddWorkingDilutionAsPicoAssayParent < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Plate::Creator.find_by_name('Pico Assay Plates').parent_plate_purposes << Purpose.find_by_name('Working Dilution')
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pcid = Plate::Creator.find_by_name!('Pico Assay Plates').id
      ppid = Purpose.find_by_name!('Working Dilution').id
      Plate::Creator::ParentPurposeRelationship.find_by_plate_creator_id_and_plate_purpose_id(pcid,ppid).destroy
    end
  end
end
