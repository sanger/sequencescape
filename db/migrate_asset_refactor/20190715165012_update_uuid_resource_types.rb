# frozen_string_literal: true

# Ensure uuids point at the new resources. We favour receptacles
# and fallback to labware in other situations
class UpdateUuidResourceTypes < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.transaction do
      Uuid.where(resource_type: 'Labware')
          .joins('INNER JOIN receptacles ON receptacles.id = resource_id')
          .update_all(resource_type: 'Receptacle')
      Uuid.where(resource_type: 'Asset')
          .update_all(resource_type: 'Labware')
    end
  end

  def down
    # As soon as even a single asset or receptacle has been created
    # we can't rollback.
    raise ActiveRecord::IrreversibleMigration
  end
end
