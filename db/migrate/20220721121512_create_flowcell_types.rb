# frozen_string_literal: true

# Table flowcell_types to store requested_flowcell_type for specific request types
class CreateFlowcellTypes < ActiveRecord::Migration[6.0]
  def change
    create_table :flowcell_types do |t|
      t.string :requested_flowcell_type, unique: true
      t.timestamps
    end
  end
end
