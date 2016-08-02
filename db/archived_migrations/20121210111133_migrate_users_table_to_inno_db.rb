#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
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
