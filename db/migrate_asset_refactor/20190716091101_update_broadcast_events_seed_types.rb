# frozen_string_literal: true

# Ensure barcodes points at labware, not assets
class UpdateBroadcastEventsSeedTypes < ActiveRecord::Migration[5.1]
  def up
    LibraryEvent.update_all(seed_type: 'Labware')
    BroadcastEvent::LabwareReceived.update_all(seed_type: 'Labware')
    BroadcastEvent::LibraryComplete.update_all(seed_type: 'Labware')
    BroadcastEvent::LibraryStart.update_all(seed_type: 'Labware')
    BroadcastEvent::SequencingComplete.update_all(seed_type: 'Receptacle')
  end

  def down
    # We can't roll back once new events have been created
    raise ActiveRecord::IrreversibleMigration
  end
end
