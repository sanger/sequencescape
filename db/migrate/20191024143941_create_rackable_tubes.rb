# frozen_string_literal: true

class CreateRackableTubes < ActiveRecord::Migration[5.2]
  def change
    create_table :rackable_tubes do |t|
      t.belongs_to :labware, index: true
      t.belongs_to :tube, index: true
      t.string :coordinate
    end
  end
end
