# frozen_string_literal: true

class CreateTubeRacks < ActiveRecord::Migration[5.2]
  def change
    create_table :tube_racks do |t|
      t.string :size
      t.timestamps
    end
  end
end
