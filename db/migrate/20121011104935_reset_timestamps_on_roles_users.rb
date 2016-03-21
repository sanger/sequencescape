#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class ResetTimestampsOnRolesUsers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Role::UserRole.find_each do |role_user|
        role_user.created_at = role_user.updated_at = Time.now
        role_user.save(:validate => false)
      end
    end
  end

  def self.down
    # Do nothing!
  end
end
