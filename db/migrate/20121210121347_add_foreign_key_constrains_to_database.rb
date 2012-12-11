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
