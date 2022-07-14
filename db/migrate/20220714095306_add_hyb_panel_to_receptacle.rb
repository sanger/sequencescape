# frozen_string_literal: true

# Adds hyb panel field for DuplexSeq and Targeted Nanoseq pipelines from Limber
class AddHybPanelToReceptacle < ActiveRecord::Migration[6.0]
  def change
    add_column :receptacles, :hyb_panel, :string
  end
end

