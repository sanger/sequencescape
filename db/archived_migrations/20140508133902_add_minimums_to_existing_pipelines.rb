#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddMinimumsToExistingPipelines < ActiveRecord::Migration
  def self.up
    SequencingPipeline.find(:all,:conditions=>{:max_size=>8}).each do |pipeline|
      pipeline.update_attributes!(:min_size=>8)
    end
  end

  def self.down
    SequencingPipeline.find(:all,:conditions=>{:max_size=>8,:min_size=>8}).each do |pipeline|
      pipeline.update_attributes!(:min_size=>nil)
    end
  end
end
