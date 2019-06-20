# frozen_string_literal: true

# Copies the container association data into the newly created receptacle column
class MigrateContainerAssociationData < ActiveRecord::Migration[4.2]
  def change
    ActiveRecord::Base.connection.execute(%{
      UPDATE receptacles r
      INNER JOIN container_associations ca ON (ca.content_id = r.id)
      INNER JOIN labware ON labware.id = ca.container_id
      SET r.labware_id = ca.container_id
      WHERE ca.container_id IS NOT NULL
    })
  end
end
