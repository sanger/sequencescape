class AddRequestTypePipelineMToMAssociation < ActiveRecord::Migration
  def self.up
    create_table :pipelines_request_types, :id => false do |t|
      t.integer :pipeline_id,     :null => false
      t.integer :request_type_id, :null => false
    end

    say 'Applying foreign key constraints to the pipelines_request_types table...'

    connection.execute(
      'alter table pipelines_request_types
       add constraint foreign key fk_pipelines_request_types_to_pipelines (pipeline_id) 
       references pipelines (id);'
    )

    connection.execute(
      'alter table pipelines_request_types 
      add constraint foreign key fk_pipelines_request_types_to_request_types (request_type_id)
      references request_types (id);'
    )
  end

  def self.down
    drop_table :pipelines_request_types
  end
end
