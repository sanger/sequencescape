#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateDefaultPlateLocations < ActiveRecord::Migration

  def self.plate_purposes
    names = IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.concat(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
    PlatePurpose.find_all_by_name(names)
  end


  def self.up
    ActiveRecord::Base.transaction do
      plate_purposes.each do |pp|
        next if pp.default_location.nil?
        pp.update_attributes!(:default_location=>Location.find_by_name("Illumina high throughput freezer"))
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      plate_purposes.each do |pp|
        next if pp.default_location.nil?
        pp.update_attributes!(:default_location=>Location.find_by_name('Library creation freezer'))
      end
    end
  end
end
