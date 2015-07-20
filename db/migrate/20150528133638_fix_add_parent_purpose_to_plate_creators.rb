#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class FixAddParentPurposeToPlateCreators < ActiveRecord::Migration
  def self.build_purpose_config_record(plate_purpose_name, parent_purpose_name)
    {
      :plate_purpose => Purpose.find_by_name!(plate_purpose_name),
      :parent_purpose => Purpose.find_by_name!(parent_purpose_name)
    }
  end

  def self.purposes_config
    [
      build_purpose_config_record("Working dilution", "Stock plate"),
      build_purpose_config_record("Pico dilution", "Working dilution"),
      build_purpose_config_record("Pico Assay Plates", "Pico dilution")
    ]
  end

  def self.up
    ActiveRecord::Base.transaction do
      change_column(:plate_creator_purposes, :parent_purpose_id, :integer)
      self.purposes_config.each do |p|
        Plate::Creator.find_by_name(p[:plate_purpose].name).plate_creator_purposes.each do |relation|
          relation.update_attributes!(:parent_purpose_id =>  p[:parent_purpose].id)
        end
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      self.purposes_config.each do |p|
        Plate::Creator.find_by_name(p[:plate_purpose].name).plate_creator_purposes.each do |relation|
          relation.update_attributes!(:parent_purpose_id =>  nil)
        end
      end
    end
  end
end
