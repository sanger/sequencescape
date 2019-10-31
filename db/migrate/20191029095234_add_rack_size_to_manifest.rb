class AddRackSizeToManifest < ActiveRecord::Migration[5.2]
  def change
    add_column :sample_manifests, :rack_size, :integer
  end
end
