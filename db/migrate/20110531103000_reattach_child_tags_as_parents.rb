class ReattachChildTagsAsParents < ActiveRecord::Migration
  def self.up
    # Find all of the TagInstance instances that are descendants, rather than ancestors, in the
    # asset links table.  Then switch their relationship.  This is not only efficient, it also
    # means we can remove the TagInstance model itself.
    ActiveRecord::Base.transaction do
      AssetLink.connection.execute(%Q{
        UPDATE asset_links,
          (
            SELECT al.id, al.ancestor_id, al.descendant_id
            FROM asset_links al, assets a
            WHERE al.descendant_id = a.id AND a.sti_type = 'TagInstance'
          ) AS broken
        SET asset_links.descendant_id = broken.ancestor_id, asset_links.ancestor_id = broken.descendant_id
        WHERE asset_links.id = broken.id
      }, "Fixing descendant TagInstance")
    end
  end

  def self.down
    # There is nothing we can do here to recover the previous state as there are only a partial
    # set of tags that were in this incorrect state.
    raise ActiveRecord::IrreversibleMigration, 'Cannot revert tag instances to descendants'
  end
end
