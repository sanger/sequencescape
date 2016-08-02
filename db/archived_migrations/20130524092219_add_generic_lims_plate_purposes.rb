#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddGenericLimsPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaC::PlatePurposes.create_plate_purposes
      IlluminaC::PlatePurposes.create_tube_purposes
      IlluminaC::PlatePurposes.create_branches
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaC::PlatePurposes.destroy_plate_purposes
      IlluminaC::PlatePurposes.destroy_tube_purposes
    end
  end
end
