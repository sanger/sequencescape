class TagGroupsNameUniqueness < ActiveRecord::Migration
  
  def self.up
    execute <<-SQL
      ALTER TABLE tag_groups
      ADD CONSTRAINT unique_name UNIQUE (name)
    SQL
  end

  def self.down
    execute <<-SQL
      ALTER TABLE tag_groups
      DROP INDEX unique_name
    SQL
  end
end
