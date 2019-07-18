# Rails migration
class RemoveAssetTypeFromQcFiles < ActiveRecord::Migration[4.2]
  def up
    remove_column :qc_files, :asset_type
  end

  def down
    add_column :qc_files, :asset_type, :string, after: :asset_id
  end
end
