class AddMultipleParents < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      create_table :asset_creation_parents do |t|
        t.references :asset_creation
        t.references :parent
        t.timestamps
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      drop_table :asset_creation_parents
    end
  end
end
