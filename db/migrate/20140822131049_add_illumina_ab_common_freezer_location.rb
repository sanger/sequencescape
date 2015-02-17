#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddIlluminaAbCommonFreezerLocation < ActiveRecord::Migration
  @freezer_name = "Illumina high throughput freezer"
  
  def self.up
    Location.create!(:name => @freezer_name)
  end

  def self.down
    Location.find_by_name(@freezer_name).delete
  end
end
