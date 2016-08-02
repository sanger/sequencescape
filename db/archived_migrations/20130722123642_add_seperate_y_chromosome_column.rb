#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class AddSeperateYChromosomeColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :study_metadata, :seperate_y_chromosome_data, :boolean, :null => false, :default => false
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :study_metadata, :seperate_y_chromosome_data
    end
  end
end
