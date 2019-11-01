# frozen_string_literal: true

# Adds a new table to link Tubes (Labware) to Tube Racks (Labware)
class CreateRackableTubes < ActiveRecord::Migration[5.2]
  def change
    create_table :rackable_tubes do |t|
      t.belongs_to :tube_rack, index: true
      t.belongs_to :tube, index: true
      t.string :coordinate
      t.timestamps null: false
    end
  end
end
