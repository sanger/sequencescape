class RenameColumnRequestedFlowcellType < ActiveRecord::Migration[6.0]
  def change
    rename_column :flowcell_types, :requested_flowcell_type, :name
  end
end
