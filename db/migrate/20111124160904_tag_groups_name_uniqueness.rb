class TagGroupsNameUniqueness < ActiveRecord::Migration
  
  # This will identify duplicates in an array
  def dup_hash(ary)
    ary.inject(Hash.new(0)) { |h,e| h[e] += 1; h }.select { 
      |k,v| v > 1 }.inject({}) { |r, e| r[e.first] = e.last; r }
  end
  
  def self.up
    
    names = TagGroup.all.collect(&:name)
    
    if (names.size!=names.uniq.size)
      dup_hash(names).map { |d|
        suffix = 1
        TagGroup.all(:conditions => { :name => d[0] }).each { |tg|
          tg.name = "#{tg.name}#{suffix}"
          tg.save
          suffix += 1
          }
      }
      
      
    end
      
    execute <<-SQL
      ALTER TABLE tag_groups
      ADD CONSTRAINT unique_name UNIQUE (name)
    SQL
  end

  def self.down
    execute <<-SQL
      ALTER TABLE tag_groups
      REMOVE CONSTRAINT unique_name
    SQL
  end
end
