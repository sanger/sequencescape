# frozen_string_literal: true

# Ensure uuids point at the new resources. We favour receptacles
# and fallback to labware in other situations
class UpdateUuidResourceTypes < ActiveRecord::Migration[5.1]
  def up
    ActiveRecord::Base.transaction do
      execute(%{UPDATE `uuids`
LEFT OUTER JOIN receptacles ON receptacles.id = resource_id
SET `uuids`.`resource_type` = IF(receptacles.id IS NULL, 'Labware', 'Receptacle')
WHERE `uuids`.`resource_type` = 'Asset'})
    end
  end

  def down
    # As soon as even a single asset or receptacle has been created
    # we can't rollback.
    raise ActiveRecord::IrreversibleMigration
  end
end
