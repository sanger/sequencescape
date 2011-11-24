class TagGroupsNameUniqueness < ActiveRecord::Migration
  
  # This will identify duplicates in an array
  def dup_hash(ary)
    ary.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select { 
      |k,v| v > 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
  end
  
  def self.up
    
    names = TagGroup.all.collect(&:name)
    unique_names = names.uniq
    
    if (names.size!=unique_names.size)
      dup_hash(names).map { |d|
        tag_groups = TagGroup.all :conditions => { :name => d[0] }
      }
      
      
    end
      
    execute <<-SQL
      ALTER TABLE tag_groups
      ADD CONSTRAINT unique_name UNIQUE (name)
    SQL
  end

  def self.down
  end
end
