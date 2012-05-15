class AddHmdmcApprovalNumber < ActiveRecord::Migration
  def self.up
    add_column :study_metadata, :hmdmc_approval_number, :string
  end

  def self.down
    remove_column :study_metadata, :hmdmc_approval_number
  end
end
