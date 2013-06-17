class AddDonorIdColumn < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      add_column :sample_metadata, :donor_id,:string
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      remove_column :sample_metadata, :donor_id
    end
  end
end
