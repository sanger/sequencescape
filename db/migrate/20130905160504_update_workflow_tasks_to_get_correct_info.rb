#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class UpdateWorkflowTasksToGetCorrectInfo < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Task.find_all_by_name('Specify Dilution Volume').each do |liw|
        liw.update_attributes!(:per_item=>true)
      end
      Task.find_all_by_name(['Read 1 Lin/block/hyb/load','Read 2 Cluster/Lin/block/hyb/load']).each do |liw|
        liw.update_attributes!(:per_item=>false)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transdaction do
      Task.find_all_by_name('Specify Dilution Volume').each do |liw|
        liw.update_attributes!(:per_item=>nil)
      end
      Task.find_all_by_name(['Read 1 Lin/block/hyb/load','Read 2 Cluster/Lin/block/hyb/load']).each do |liw|
        liw.update_attributes!(:per_item=>true)
      end
    end
  end
end
