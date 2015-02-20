#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2013 Genome Research Ltd.
class MoveMiSeqPipelineUnderSequencing < ActiveRecord::Migration
  def self.up
    Pipeline.find_by_name('MiSeq sequencing').update_attributes!(:group_name => 'Sequencing')
  end

  def self.down
    Pipeline.find_by_name('MiSeq sequencing').update_attributes!(:group_name => 'R&D')
  end
end
