# frozen_string_literal: true

class AddPrimerPanelIdToRequestMetadata < ActiveRecord::Migration[5.1]
  def change
    add_column :request_metadata, :primer_panel_id, :integer
  end
end
