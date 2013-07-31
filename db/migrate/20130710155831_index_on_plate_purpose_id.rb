class IndexOnPlatePurposeId < ActiveRecord::Migration
  def self.up
    add_index :assets, ['sti_type','plate_purpose_id'], :name=> "index_assets_on_plate_purpose_id_sti_type"
  end

  def self.down
    remove_index :name=> "index_assets_on_plate_purpose_id_sti_type"
  end
end
