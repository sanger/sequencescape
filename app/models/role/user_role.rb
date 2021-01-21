# frozen_string_literal: true

# Simple join table of {Role roles} to {User users}
class Role::UserRole < ApplicationRecord
  self.table_name = 'roles_users'

  belongs_to :role
  belongs_to :user

  after_destroy :touch_authorizable

  delegate :touch_authorizable, :authorizable, to: :role

  broadcasts_associated_via_warren :authorizable
end
