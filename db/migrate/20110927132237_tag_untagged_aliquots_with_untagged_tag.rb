class TagUntaggedAliquotsWithUntaggedTag < ActiveRecord::Migration
  class Aliquot < ActiveRecord::Base
    set_table_name('aliquots')

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
