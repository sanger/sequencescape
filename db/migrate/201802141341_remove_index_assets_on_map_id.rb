# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexAssetsOnMapId < ActiveRecord::Migration[5.1]
  remove_index :assets, column: ['map_id']
end
