class TagGroupsNameUniqueness < ActiveRecord::Migration
  
  def self.up
    execute <<-SQL
      ALTER TABLE tag_groups
      ADD CONSTRAINT tag_groups_unique_name UNIQUE (name)
    SQL
  end

  def self.down
    execute <<-SQL
      ALTER TABLE tag_groups
      DROP INDEX tag_groups_unique_name
    SQL
  end
end
