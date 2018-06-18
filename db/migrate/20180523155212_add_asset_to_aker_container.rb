# frozen_string_literal: true

# Adds asset id related with the container
#
class AddAssetToAkerContainer < ActiveRecord::Migration[5.1]
  def change
    add_column :aker_containers, :asset_id, :integer
  end
end
