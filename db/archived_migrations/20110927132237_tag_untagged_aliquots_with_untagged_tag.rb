#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class TagUntaggedAliquotsWithUntaggedTag < ActiveRecord::Migration
  class Aliquot < ActiveRecord::Base
    self.table_name =('aliquots')

    def self.tag_untagged(details)
      conditions = details[:from].nil? ? 'tag_id IS NULL' : [ 'tag_id=?', details[:from] ]
      self.update_all("tag_id=#{details[:to] || 'NULL'}", conditions)
    end
  end

  def self.up
    Aliquot.tag_untagged(:from => nil, :to => -1)
  end

  def self.down
    Aliquot.tag_untagged(:from => -1, :to => nil)
  end
end
