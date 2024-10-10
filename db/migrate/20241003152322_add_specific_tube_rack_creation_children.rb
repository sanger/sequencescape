# frozen_string_literal: true
class AddSpecificTubeRackCreationChildren < ActiveRecord::Migration[6.1]
  def change
    create_table :specific_tube_rack_creation_children do |t|
      t.integer :specific_tube_rack_creation_id, null: false
      t.integer :tube_rack_id, null: false

      t.timestamps
    end
  end
end
