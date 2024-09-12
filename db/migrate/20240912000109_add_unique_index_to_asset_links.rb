# frozen_string_literal: true

require 'csv'
# This migration adds a unique-together index on ancestor_id and descendant_id
# in order to prevent duplicate links between the same ancestor and descendant
# labware.
#
# Before this migration, the database allowed duplicate asset_links between the
# same ancestor and descendant labware. Therefore, the migration will fail if
# there are any duplicate links in the database. To fix this, they must be
# removed before running the migration using the rake task:
#
# bundle exec rake 'support:remove_duplicate_asset_links[csv_file_path]'
#
# The rake task will write the removed records into a CSV file that can be used
# for recovery if necessary.
#
# If the migration is rolled back, the index will be removed. The duplicate
# records removed before can be restored from a CSV using the rake task:
#
# bundle exec rake 'support:restore_removed_asset_links[csv_file_path]'
#
class AddUniqueIndexToAssetLinks < ActiveRecord::Migration[6.1]
  def change
    add_index :asset_links,
              %i[ancestor_id descendant_id],
              unique: true,
              name: 'index_asset_links_on_ancestor_and_descendant'
  end
end
