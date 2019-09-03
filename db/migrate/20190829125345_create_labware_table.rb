# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class CreateLabwareTable < ActiveRecord::Migration[4.2]
  def change
    say "LAST ASSET #{Asset.order(id: :desc).first&.id || 'NONE'}"
    create_table 'labware' do |t|
      t.string 'name'
      t.string 'sti_type', limit: 50, null: false, default: 'Labware'
      t.integer 'size'
      t.string 'public_name'
      t.string 'two_dimensional_barcode'
      t.integer 'plate_purpose_id'
      t.integer 'labware_type_id'
      t.timestamps null: false
    end
  end
end
