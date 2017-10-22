class DropSampleManifestTemplate < ActiveRecord::Migration
  def up
    drop_table :sample_manifest_templates
  end

  def down
    create_table 'sample_manifest_templates', force: true do |t|
      t.string 'name'
      t.string 'asset_type'
      t.string 'path'
      t.string 'default_values'
      t.string 'cell_map'
    end
  end
end
