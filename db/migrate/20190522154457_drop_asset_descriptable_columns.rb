# frozen_string_literal: true

# Finally we drop the descriptors and descriptor_fields
class DropAssetDescriptableColumns < ActiveRecord::Migration[5.1]
  def change
    remove_column :assets, :descriptors, :text
    remove_column :assets, :descriptor_fields, :text
  end
end
