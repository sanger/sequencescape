# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class AddLabwareIndicies < ActiveRecord::Migration[4.2]
  def change
    add_index :labware, %i[sti_type plate_purpose_id]
    add_index :labware, %i[sti_type updated_at]
    add_index :labware, :updated_at
    add_foreign_key :labware, :plate_types, column: :labware_type_id
    add_foreign_key :labware, :plate_purposes, column: :plate_purpose_id
    ActiveRecord::Base.connection.execute('ANALYZE TABLE labware')
  end
end
