#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class NewPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.create_plate_purposes
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      IlluminaHtp::PlatePurposes.destroy_plate_purposes
    end
  end

end
