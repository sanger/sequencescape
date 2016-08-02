#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddIlluminaBPlateAndTubePurposes < ActiveRecord::Migration
  def self.up
    do_it(:create)
  end

  def self.down
    do_it(:destroy)
  end

  def self.do_it(action)
    ActiveRecord::Base.transaction do
      IlluminaB::PlatePurposes.send(:"#{action}_tube_purposes")
      IlluminaB::PlatePurposes.send(:"#{action}_plate_purposes")
      IlluminaB::PlatePurposes.send(:"#{action}_branches")
    end
  end
end
