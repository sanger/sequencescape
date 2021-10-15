# frozen_string_literal: true

# Add columns to specify source and destination well for the compound sample
class AddAssetTargetAssetToCompoundSample < ActiveRecord::Migration[6.0]
  def change
    add_column :sample_compounds_components, :asset_id, :integer, null: true
    add_column :sample_compounds_components, :target_asset_id, :integer, null: true
  end
end
