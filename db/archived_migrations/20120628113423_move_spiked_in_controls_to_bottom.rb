#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class MoveSpikedInControlsToBottom < ActiveRecord::Migration
  def self.up
    Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').update_attributes!(:sorter=>9)
  end

  def self.down
    Pipeline.find_by_name('HiSeq Cluster formation PE (spiked in controls)').update_attributes!(:sorter=>8)
  end
end
