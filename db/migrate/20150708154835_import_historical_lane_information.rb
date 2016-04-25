#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.

class ImportHistoricalLaneInformation < ActiveRecord::Migration

  require './lib/aliquot_tag_migration'

  class AliquotIndex < ActiveRecord::Base
    self.table_name=('aliquot_indices')
  end

  def self.up
    min_aliquot = ENV['MIN_ALIQUOT']||0
    say "Preparing to migrate: #{AliquotTagMigration::MigratableAliquots.count} aliquots"
    last_id = 0
    dual_tagged_lanes = []
    AliquotTagMigration::MigratableAliquots.find_in_batches(:conditions => ['aliquots.id >= ?',min_aliquot]) do |batch|
      ActiveRecord::Base.transaction do
        say "Migrating #{batch.first.id}-#{batch.last.id}"
        last_id = batch.last.id
        batch.each do |ma|
          if ma.tag2_id != -1
            dual_tagged_lanes << ma.lane_id
            say "Skipping Aliquot #{ma.id}"
            next
          end
          AliquotIndex.create!(:aliquot_id=>ma.id,:lane_id=>ma.lane_id,:aliquot_index=>ma.aliquot_index)
        end
      end
    end
    ActiveRecord::Base.transaction do
      dual_tagged_lanes.uniq!
      say "Updating #{dual_tagged_lanes.count} dual tagged lanes!"
      dual_tagged_lanes.each do |lane_id|
        Lane.find(lane_id).index_aliquots
      end
    end
    say "Last aliquot updated: #{last_id}. This should be noted to assist with rollbacks."
  end

  def self.down
    max_aliquot = ENV['MAX_ALIQUOT']
    raise "You must specify MAX_ALIQUOT to rollback the migration" unless max_aliquot
    say "Preparing to revert up to: #{AliquotTagMigration::MigratableAliquots.count} aliquots"
    AliquotTagMigration::MigratableAliquots.find_in_batches(:conditions => ['aliquots.id <= ?',max_aliquot]) do |batch|
      ActiveRecord::Base.transaction do
        say "Migrating #{batch.first.id}-#{batch.last.id}"
        batch.each do |ma|
          AliquotIndex.find(:first, :conditions => {:aliquot_id=>ma.id}).destroy
        end
      end
    end
  end
end
