
class AddVerisonIdColumnToCriteria < ActiveRecord::Migration
  def self.up
    add_column :product_criteria, :version, :integer
    add_index :product_criteria, [:product_id, :stage, :version], unique: true
  end

  def self.down
    remove_index :product_criteria, [:product_id, :stage, :version]
    remove_column :product_criteria, :version
  end
end
