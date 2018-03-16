# frozen_string_literal: true

# In order to avoid complicated lookup of requests, we store the information
# on aliquot along with the other metadata
class AddPrimerPanelIdToAliquots < ActiveRecord::Migration[5.1]
  def change
    add_reference(:aliquots, :primer_panel, foreign_key: true)
  end
end
