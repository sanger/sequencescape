# frozen_string_literal: true

class AddProgramsToPrimerPanels < ActiveRecord::Migration[5.1]
  def change
    add_column :primer_panels, :programs, :string
  end
end
