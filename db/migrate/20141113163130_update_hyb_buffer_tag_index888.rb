#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class UpdateHybBufferTagIndex888 < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      configatron.phyx_tag.tag_group_name
      tag_group = TagGroup.create!(:name => configatron.phyx_tag.tag_group_name)
      copied_tag = TagGroup.find_by_name("Sanger_168tags - 10 mer tags").tags.select do |t|
        t.map_id==168
      end.first
      tag_group.tags.create!(:map_id => configatron.phyx_tag.tag_map_id, :oligo => copied_tag.oligo)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      t = TagGroup.find_by_name(configatron.phyx_tag.tag_group_name)
      t.tags.each do |tag|
        tag.destroy
      end
      t.destroy
    end
  end
end
