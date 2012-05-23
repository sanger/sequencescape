class PipelinesRequestType < ActiveRecord::Base; end

class MoveExistingPipelineRequestTypeAssociationToJoinTable < ActiveRecord::Migration
  def self.up
    say 'Copying pipeline request_type_ids into pipeline_request_types'

    connection.execute(<<-EO_SQL
INSERT INTO `pipelines_request_types` (pipeline_id, request_type_id)
SELECT id AS pipeline_id, `request_type_id`
FROM pipelines
EO_SQL
    )

    remove_column :pipelines, :request_type_id
  end

  def self.down
    add_column :pipelines, :request_type_id, :integer

    connection.execute(<<-EO_SQL
      UPDATE pipelines
      SET pipelines.request_type_id = (
        SELECT pipelines_request_types.id
        FROM pipelines_request_types
        WHERE pipelines_request_types.pipeline_id = pipelines.id limit 1
      )
      EO_SQL
    )

    say 'Removing all records from pipelines_request_types'
    PipelinesRequestType.destroy_all
  end
end
