#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class DropUnusedClusterFormationWorkflow < ActiveRecord::Migration
  def self.up
    LabInterface::Workflow.find_by_name('Cluster formation SE_dup_fake_2').try(:destroy)
  end

  def self.down
    # Really nothing to do here because this shouldn't exist anyway.
  end
end
