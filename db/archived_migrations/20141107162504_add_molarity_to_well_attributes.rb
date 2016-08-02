#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AddMolarityToWellAttributes < ActiveRecord::Migration
  def self.up
  	ActiveRecord::Base.transaction do
  		change_table :well_attributes do |t|
  			t.float :molarity
  		end
  	end
  end

  def self.down
  	ActiveRecord::Base.transaction do
  		change_table :well_attributes do |t|
  			t.remove :molarity
  		end
  	end
  end
end
