# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class CreateReceptaclesTable < ActiveRecord::Migration[4.2]
  def change
    create_table 'receptacles' do |t|
      t.string 'sti_type', limit: 50, null: false, default: 'Receptacle'
      t.string 'qc_state', limit: 20
      t.boolean 'resource'
      t.integer 'map_id'
      t.boolean 'closed', default: false
      t.boolean 'external_release'
      t.decimal 'volume', precision: 10, scale: 2
      t.decimal 'concentration', precision: 18, scale: 8
      t.integer 'labware_id'
      t.timestamps null: false
    end
  end
end
