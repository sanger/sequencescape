class AddForeignKeysFromAssetLinks < ActiveRecord::Migration
  def self.up
    connection.update(%Q{
      ALTER TABLE asset_links
      ADD FOREIGN KEY ancestor_fk(ancestor_id)     REFERENCES assets(id),
      ADD FOREIGN KEY descendant_fk(descendant_id) REFERENCES assets(id)
    })
  end

  def self.down
    connection.update(%Q{
      ALTER TABLE asset_links
      DROP FOREIGN KEY ancestor_fk,
      DROP FOREIGN KEY descendant_fk
    })
  end
end
