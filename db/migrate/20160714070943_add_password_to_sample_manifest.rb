class AddPasswordToSampleManifest < ActiveRecord::Migration
  def change
    add_column :sample_manifests, :password, :string
  end
end
