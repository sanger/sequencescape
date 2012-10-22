class LinkWellsToStockWells < ActiveRecord::Migration
  def self.up
    create_table(:well_links) do |t|
      t.references(:target_well, :null => false)
      t.references(:source_well, :null => false)
      t.string(:type, :null => false)
    end
    add_index([:target_well, :source_well, :type], :name => :unique_well_link_types_idx, :uniq => true)
  end

  def self.down
    drop_table(:well_links)
  end
end
