class AddQcInformationTable < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :qc_information do |t|
        t.references :asset, :polymorphic => true
        t.integer 'size'
        t.string 'content_type'
        t.string 'filename'
        t.referenced :db_file
        t.timestamps
      end
    end
  end

  def self.down
    drop_table :qc_information
  end
end
