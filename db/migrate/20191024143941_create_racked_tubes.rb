# frozen_string_literal: true

# Adds a new table to link Tubes (Labware) to Tube Racks (Labware)
class CreateRackedTubes < ActiveRecord::Migration[5.2]
  def change
    create_table :racked_tubes do |t|
      t.belongs_to :tube_rack, index: true
      t.belongs_to :tube, index: true
      t.string :coordinate
      t.timestamps null: false
    end
  end
end
