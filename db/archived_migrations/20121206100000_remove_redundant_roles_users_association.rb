#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class RemoveRedundantRolesUsersAssociation < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      uc, rc = User.count, Role.count
      Role::UserRole.find(:all, {:joins=>['LEFT OUTER JOIN roles on roles.id = roles_users.role_id LEFT OUTER JOIN users on users.id = roles_users.user_id'], :conditions=>['roles.id IS NULL OR users.id IS NULL']}).map(&:destroy)
      raise "Something is deleting over the relationship" if uc != User.count || rc != Role.count
    end
  end

  def self.down
    say "Can not revert"
  end
end
