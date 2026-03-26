# frozen_string_literal: true

# Adds index to labware name to speed up search queries.
class AddLabwareNameIndex < ActiveRecord::Migration[7.2]
  def change
    add_index :labware, :name
  end
end
