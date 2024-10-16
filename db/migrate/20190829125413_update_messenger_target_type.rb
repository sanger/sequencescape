# frozen_string_literal: true

# Ensure events point at the appropriate class
class UpdateMessengerTargetType < ActiveRecord::Migration[5.1]
  def up
    Messenger.where(target_type: 'Asset').where(template: 'FluidigmPlateIo').update_all(target_type: 'Labware')
    Messenger.where(target_type: 'Asset').where(root: 'stock_resource').update_all(target_type: 'Receptacle')
  end

  def down
    # We can't roll back once new events have been created
    raise ActiveRecord::IrreversibleMigration
  end
end
