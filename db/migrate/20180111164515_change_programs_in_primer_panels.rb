# frozen_string_literal: true

class ChangeProgramsInPrimerPanels < ActiveRecord::Migration[5.1]
  def change
    change_column :primer_panels, :programs, :text
  end
end
