# frozen_string_literal: true

# Destination type IS NOT polymorphic in the manner that the property implies
# polymorphic: true is only required if an association joins to more than one table.
# Even post asset-refactor this will not be the case
class DropDestinationTypeColumn < ActiveRecord::Migration[5.1]
  def up
    remove_column :transfers, :destination_type, :string
  end

  def down
    add_column :transfers, :destination_type, :string
    Transfer.where.not(destination_id: nil).update_all(destination_type: 'Asset')
  end
end
