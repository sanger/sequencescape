# frozen_string_literal: true

# Rename the assets table to ensure we no longer accidentally use it
class RenameAssetsTable < ActiveRecord::Migration[4.2]
  def change
    rename_table 'assets', 'assets_deprecated'
  end
end
