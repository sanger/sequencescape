class CreateDatabaseArchive < ActiveRecord::Migration
  require 'lib/db_table_archiver'
  def self.up
    DbTableArchiver.create_archive!
  end

  def self.down
    DbTableArchiver.destroy_archive!
  end
end
