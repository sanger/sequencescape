#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class TagsUniquenessDependsOnIndexTag < ActiveRecord::Migration
  def self.up
    remove_index "aliquots", :name => "aliquot_tags_are_unique_within_receptacle"
    add_index "aliquots", ["receptacle_id", "tag_id","tag2_id"], :name => "aliquot_tags_and_tag2s_are_unique_within_receptacle", :unique => true
  end

  def self.down
    remove_index "aliquots", :name =>  "aliquot_tags_and_tag2s_are_unique_within_receptacle"
    add_index "aliquots", ["receptacle_id", "tag_id"], :name => "aliquot_tags_are_unique_within_receptacle", :unique => true
  end
end
