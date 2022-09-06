# frozen_string_literal: true

# Renames columns from database
class RenameColumnFlowcellTypesRequestTypes < ActiveRecord::Migration[6.0]
  def change
    rename_column :flowcell_types_request_types, :request_types_id, :request_type_id
    rename_column :flowcell_types_request_types, :flowcell_types_id, :flowcell_type_id
  end
end
