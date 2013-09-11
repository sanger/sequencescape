class RenameCancerDonorIdColumn < ActiveRecord::Migration
  def self.up
    rename_column :sample_metadata, :cancer_donor_id, :donor_id
  end

  def self.down
    rename_column :sample_metadata, :donor_id, :cancer_donor_id
  end
end
