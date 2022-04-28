# frozen_string_literal: true

# Customers specify the primer panel; they want, so this is tracked on request metadata
class AddPrimerPanelIdToRequestMetadata < ActiveRecord::Migration[5.1]
  def change
    add_column :request_metadata, :primer_panel_id, :integer
  end
end
