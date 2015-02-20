#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class AddForeignKeyConstrainsToDatabase < ActiveRecord::Migration
  def self.up
      say 'Applying foreign key constraints to roles_users table'
      begin
        connection.execute(
          'ALTER TABLE roles_users
            add constraint `fk_roles_users_to_users`
              foreign key (user_id)
          references users (id);'
        )
        connection.execute(
          'alter table roles_users
            add constraint `fk_roles_users_to_roles`
              foreign key (role_id)
          references roles (id);'
        )
      rescue
        connection.execute('alter table roles_users DROP FOREIGN KEY `fk_roles_users_to_users`;')
        connection.execute('alter table roles_users DROP FOREIGN KEY `fk_roles_users_to_roles`;')
      end
  end

  def self.down
    ActiveRecord::Base.transaction do
      connection.execute('alter table roles_users DROP FOREIGN KEY `fk_roles_users_to_roles`;')
      connection.execute('alter table roles_users DROP FOREIGN KEY `fk_roles_users_to_users`;')
    end
  end
end
