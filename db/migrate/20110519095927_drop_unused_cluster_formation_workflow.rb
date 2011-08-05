class DropUnusedClusterFormationWorkflow < ActiveRecord::Migration
  def self.up
    LabInterface::Workflow.find_by_name('Cluster formation SE_dup_fake_2').try(:destroy)
  end

  def self.down
    # Really nothing to do here because this shouldn't exist anyway.
  end
end
