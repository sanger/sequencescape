#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddNumberOfGigabasesToStudyMetadata < ActiveRecord::Migration
  def self.up
    add_column :study_metadata, :number_of_gigabases_per_sample, :float
  end

  def self.down
    remove_column :study_metadata, :number_of_gigabases_per_sample
  end
end
