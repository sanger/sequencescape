class RemoveInvalidAssetLinks < ActiveRecord::Migration
  def self.up
    # Remove any asset links that reference an asset that no longer exists
    ActiveRecord::Base.transaction do
      connection.update(%Q{
        DELETE asset_links
        FROM asset_links
        LEFT JOIN assets AS ancestors   ON asset_links.ancestor_id=ancestors.id
        LEFT JOIN assets AS descendants ON asset_links.descendant_id=descendants.id
        WHERE ancestors.id IS NULL OR descendants.id IS NULL
      })
    end
  end

  def self.down
    # Do nothing
  end
end
