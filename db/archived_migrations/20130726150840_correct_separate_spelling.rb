#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class CorrectSeparateSpelling < ActiveRecord::Migration
  def self.up
    rename_column :study_metadata, :seperate_y_chromosome_data, :separate_y_chromosome_data
  end

  def self.down
    rename_column :study_metadata, :separate_y_chromosome_data, :seperate_y_chromosome_data
  end
end
