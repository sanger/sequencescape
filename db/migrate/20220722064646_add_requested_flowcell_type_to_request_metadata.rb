# frozen_string_literal: true

# Adding requested_flowcell_type column to request_metadata
class AddRequestedFlowcellTypeToRequestMetadata < ActiveRecord::Migration[6.0]
  def change
    add_column :request_metadata, :requested_flowcell_type, :string
  end
end
