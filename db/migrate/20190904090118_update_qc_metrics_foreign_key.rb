# frozen_string_literal: true

# Remove foreign key pointing at old tables
class UpdateQcMetricsForeignKey < ActiveRecord::Migration[5.1]
  def up
    remove_foreign_key :qc_metrics, column: :asset_id
    add_foreign_key :qc_metrics, :receptacles, column: :asset_id
  end

  def down
    remove_foreign_key :qc_metrics, column: :asset_id
    add_foreign_key :qc_metrics, :assets_deprecated, column: :asset_id
  end
end
