# frozen_string_literal: true
class AddSpecificTubeRackCreationPurposes < ActiveRecord::Migration[6.1]
  def change
    create_table :specific_tube_rack_creation_purposes do |t|
      t.integer :specific_tube_rack_creation_id, null: false
      t.integer :tube_rack_purpose_id, null: false

      t.timestamps
    end
  end
end
