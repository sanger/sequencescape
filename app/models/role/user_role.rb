# frozen_string_literal: true

# Simple join table of {Role roles} to {User users}
class Role::UserRole < ApplicationRecord
  self.table_name = 'roles_users'

  belongs_to :role, touch: true
  belongs_to :user

  after_destroy :touch_authorizable

  delegate :touch_authorizable, :authorizable, to: :role

end
