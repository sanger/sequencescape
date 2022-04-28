# frozen_string_literal: true

# Programs track information about PCR processes associated with a primer panel
class AddProgramsToPrimerPanels < ActiveRecord::Migration[5.1]
  def change
    add_column :primer_panels, :programs, :string
  end
end
