class UuidMigration < ActiveRecord::Migration
  class_inheritable_accessor :model_to_migrate

  def self.up
    Uuid.transaction do
      count = 0

      model_to_migrate.find_in_batches do |batch|
        say_with_time("Generating #{model_to_migrate.name} UUIDs #{count}-#{count+batch.size-1} ...") do
          Uuid.import(
            [ 'resource_type', 'resource_id', 'external_id' ],
            batch.map { |record| [ (record.respond_to?(:sti_type) ? record.sti_type : record.class.name), record.id, Uuid.generate_uuid ] }
          )
        end

        count += batch.size
      end
    end
  end

  def self.down
    # Not really anything we should be doing here, except maybe deleting all of the UUIDs?
  end
end
