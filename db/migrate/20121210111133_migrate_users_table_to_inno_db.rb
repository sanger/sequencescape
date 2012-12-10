class MigrateUsersTableToInnoDb < ActiveRecord::Migration
  def self.up
    # The Alter table is atomic, table locking and transactional.  What's not
    # to love...
    execute <<-SQL
      ALTER TABLE users ENGINE=InnoDB
    SQL
  end

  def self.down
    # Well it probably can but...
    raise "This cannot be undone!"
  end
end
