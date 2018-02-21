# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ApplicationRecord
  class UserRole < ApplicationRecord
    self.table_name = ('roles_users')
    belongs_to :role
    belongs_to :user

    after_destroy :touch_authorizable

    delegate :touch_authorizable, :authorizable, to: :role

    broadcasts_associated_via_warren :authorizable
  end

  has_many :user_role_bindings, class_name: 'Role::UserRole'
  has_many :users, through: :user_role_bindings, source: :user

  belongs_to :authorizable, polymorphic: true

  validates_presence_of :name
  scope :general_roles, -> { where('authorizable_type IS NULL') }

  after_destroy :touch_authorizable

  broadcasts_associated_via_warren :authorizable

  def self.keys
    Role.all.map { |r| r.name }.uniq
  end

  def touch_authorizable
    authorizable.touch unless authorizable.nil?
  end

  # Include this module into your ActiveRecord model and get has_many roles and some
  # utility named_scopes.  You also get the ability to define role relations by name
  # through the role_relation class method.
  module Authorized
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_eval do
        has_many :roles, as: :authorizable
        has_many :users, through: :roles

        scope :with_related_users_included, -> { includes(roles: :users) }
        scope :with_related_owners_included, -> { includes(:owners) }
        scope :of_interest_to, ->(user) { joins(:users).where(users: { id: user }).distinct }
      end
    end

    module ClassMethods
      def role_relation(name, role_name)
        scope name.to_sym, ->(user) {
          joins(:roles, :users)
            .where(roles: { name: role_name.to_s }, users: { id: user.id })
        }
      end
    end
  end
end
