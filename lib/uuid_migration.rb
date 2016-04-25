#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
class UuidMigration < ActiveRecord::Migration
  class_attribute :model_to_migrate

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
