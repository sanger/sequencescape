# frozen_string_literal: true

# No we've standardized transfer requests, we no longer need this table,
# but rather than outright removing it, we'll rename it until we're sure
# that everything is good.
class RemovePlatePurposeReleationshipsTable < ActiveRecord::Migration[5.1]
  def change
    rename_table :plate_purpose_relationships, :plate_purpose_relationships_bkp
  end
end
