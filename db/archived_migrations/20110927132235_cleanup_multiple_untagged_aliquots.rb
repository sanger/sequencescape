#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class CleanupMultipleUntaggedAliquots < ActiveRecord::Migration
  class Aliquot < ActiveRecord::Base
    self.table_name =('aliquots')
  end

  class Receptacle < ActiveRecord::Base
    self.table_name =('assets')

    has_many :aliquots, :class_name => 'CleanupMultipleUntaggedAliquots::Aliquot', :foreign_key => :receptacle_id

    def self.find_with_duplicate_untagged_aliquots(options = {}, &block)
      self.connection.select_all(%q{
        SELECT assets.id AS id
        FROM assets
        INNER JOIN aliquots ON assets.id=aliquots.receptacle_id
        WHERE aliquots.tag_id IS NULL
        GROUP BY assets.id, aliquots.sample_id
        HAVING count(*) > 1;
      }).in_groups_of(500) do |details|
        details.compact!
        next if details.empty?
        self.all(options.merge(:conditions => { :id => details.map { |d| d['id'] } })).each(&block)
      end
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      count = 0
      Receptacle.find_with_duplicate_untagged_aliquots(:include => :aliquots) do |receptacle|
        # Eliminate duplicate aliquots for a sample in the current receptacle
        receptacle.aliquots.group_by(&:sample_id).each do |sample_id, aliquots|
          aliquots = aliquots.sort_by(&:updated_at).reverse

          save_this_aliquot   = aliquots.detect { |a| a.tag_id.present? }      # Take the one with a tag ...
          save_this_aliquot ||= aliquots.detect { |a| a.library_id.present? }  # ... otherwise try library ...
          save_this_aliquot ||= aliquots.first                                 # ... failing that the first one, by updated_at

          aliquots.reject { |a| a == save_this_aliquot }.map(&:destroy)
        end

        # If there are multiply untagged aliquots across samples in this receptacle then we have
        # a bit of a problem!
        untagged_aliquots = receptacle.aliquots(true).select { |a| a.tag_id.nil? }
        raise "There are multiple untagged aliquots in #{receptacle.id}" if untagged_aliquots.size > 1

        count += 1
      end

      say("Completed processing #{count} receptacles")
    end
  end

  def self.down
    # Nothing to do in the down bit
  end
end
