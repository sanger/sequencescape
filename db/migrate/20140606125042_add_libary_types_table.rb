class AddLibaryTypesTable < ActiveRecord::Migration

  require './lib/foreign_key_constraint'
  extend ForeignKeyConstraint

  def self.up
    # say 'Creating the library types table...'
    # create_table(:library_types) do |t|
    #   t.string :name,  :null => false
    #   t.timestamps
    # end

    # say 'Creating the association table...'
    # create_table :library_types_request_types, :id => false do |t|
    #   t.references :request_type, :null => false
    #   t.references :library_type, :null => false
    #   t.boolean :is_default, :default => false
    #   t.timestamps

    #   t.add_index(:request_type_id)
    #   t.add_indes(:library_type_id)
    # end

    add_constraint('library_types_request_types','request_types')
    add_constraint('library_types_request_types','library_types')
  end

  def self.down
    drop_table(:library_types_request_types)
    drop_table(:library_types)
  end

end
