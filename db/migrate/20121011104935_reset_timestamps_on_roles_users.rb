class ResetTimestampsOnRolesUsers < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      Role::UserRole.find_each do |role_user|
        role_user.created_at = role_user.updated_at = Time.now
        role_user.save(false)
      end
    end
  end

  def self.down
    # Do nothing!
  end
end
