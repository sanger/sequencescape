# frozen_string_literal: true

# Duplicated the contents of the assets table into receptacles and labware
class AddReceptacleIndicies < ActiveRecord::Migration[4.2]
  def change
    add_index :receptacles, %i[sti_type updated_at]
    add_index :receptacles, :updated_at
    add_foreign_key :receptacles, :labware, column: :labware_id
    ActiveRecord::Base.connection.execute('ANALYZE TABLE receptacles')
  end
end
