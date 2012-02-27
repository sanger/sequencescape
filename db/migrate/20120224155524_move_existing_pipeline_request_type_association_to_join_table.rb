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
  end

  def self.down
    say 'Removing all records from pipelines_request_types'

    PipelinesRequestType.destroy_all
  end
end
