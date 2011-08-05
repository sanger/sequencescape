class CreateTransferTemplates < ActiveRecord::Migration
  def self.up
    create_table :transfer_templates do |t|
      t.timestamps
      t.string :name
      t.string :transfer_class_name
      t.string :transfers, :limit => 1024
    end
  end

  def self.down
    drop_table :transfer_templates
  end
end
