#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class BlankAnyNamesOnWells < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Well.find_each(:conditions => 'name IS NOT NULL AND LENGTH(name) > 0') do |well|
        well.update_attributes!(:name => nil)
      end
    end
  end

  def self.down
    # Nothing to do
  end
end
