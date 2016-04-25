#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class FakeTagsOnMultipleUntaggedAliquots < ActiveRecord::Migration
  class Aliquot < ActiveRecord::Base
    self.table_name =('aliquots')

    UNASSIGNED_TAG = -1

    def self.unset_fake_tags_for_multiple_aliquots
      self.update_all('tag_id=NULL', [ 'tag_id < ?', UNASSIGNED_TAG ])
    end
  end

  class Asset < ActiveRecord::Base
    self.table_name =('assets')

    has_many :aliquots, :class_name => 'FakeTagsOnMultipleUntaggedAliquots::Aliquot', :foreign_key => :receptacle_id

    def self.find_with_multiple_untagged_aliquots(options = {}, &block)
      self.connection.select_all(%Q{
        SELECT receptacle_id AS id
        FROM aliquots
        WHERE tag_id IS NULL
        GROUP BY receptacle_id
        HAVING COUNT(*) > 1
      }).in_groups_of(500) do |details|
        details.compact!
        next if details.empty?
        self.all(options.merge(:conditions => { :id => details.map { |d| d['id'] } })).each(&block)
      end
    end
  end

  def self.up
    ActiveRecord::Base.transaction do
      Asset.find_with_multiple_untagged_aliquots(:include => :aliquots) do |receptacle|
        receptacle.aliquots.each_with_index do |aliquot, index|
          aliquot.update_attributes!(:tag_id => Aliquot::UNASSIGNED_TAG - index - 1)
        end
      end
    end
  end

  def self.down
    Aliquot.unset_fake_tags_for_multiple_aliquots
  end
end
