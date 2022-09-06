# frozen_string_literal: true

# Add index to flowcell_types name
class AddUniqueIndexToRequestedFlowcellTypeName < ActiveRecord::Migration[6.0]
  def change
    add_index :flowcell_types, :name, unique: true
  end
end
