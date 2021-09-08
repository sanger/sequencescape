# frozen_string_literal: true
# Add the pick-list table
# Contains just two columns, state and submission_id
class CreatePickLists < ActiveRecord::Migration[5.2]
  def change
    create_table :pick_lists do |t|
      t.integer :state, null: false, default: 0
      t.references :submission, foreign_key: true, type: :integer, null: false

      t.timestamps
    end
  end
end
