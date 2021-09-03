# frozen_string_literal: true
# GH Issue #2758 (GPL-438)
# Add text column for serializing data about individual audits to record specific
# beds etc.
class AddMetadataToAssetAudit < ActiveRecord::Migration[5.2]
  def change
    add_column :asset_audits, :metadata, :json
  end
end
