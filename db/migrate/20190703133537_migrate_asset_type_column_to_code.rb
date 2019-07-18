# frozen_string_literal: true

# Asset type has been migrated onto a class_attribute
# while this is less powerful it makes it much easier to track
# pipeline behaviour.
class MigrateAssetTypeColumnToCode < ActiveRecord::Migration[5.1]
  def change
    remove_column :pipelines, :asset_type, :string
  end
end
