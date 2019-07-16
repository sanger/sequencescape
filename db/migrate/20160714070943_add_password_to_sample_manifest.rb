# Passwords are used to protect manifests and are stored in the database
class AddPasswordToSampleManifest < ActiveRecord::Migration
  def change
    add_column :sample_manifests, :password, :string
  end
end
