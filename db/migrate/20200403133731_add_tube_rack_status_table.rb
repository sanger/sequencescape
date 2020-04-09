# frozen_string_literal: true

# Add table to track tube rack statuses
class AddTubeRackStatusTable < ActiveRecord::Migration[5.2]
  def change
    create_table :tube_rack_statuses do |t|
      t.string 'barcode', null: false
      t.integer 'status', null: false
      t.text 'messages'
      t.integer 'labware_id'
      t.timestamps null: false
    end
  end
end
