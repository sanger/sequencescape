class AddTableEquipment < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :equipment do |t|
        t.string :name
        t.string :type
        t.string :prefix, :limit => 2, :null => false
        t.string :ean13_barcode, :limit => 13, :null => false
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :equipment
    end
  end
end
