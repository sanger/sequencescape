# frozen_string_literal: true

# Include this module into your ActiveRecord model and get has_many roles and some
# utility named_scopes.  You also get the ability to define role relations by name
# through the role_relation class method.
# These relationships are intended for owned resources
module Role::Authorized
  extend ActiveSupport::Concern

  included do
    has_many :roles, as: :authorizable, dependent: :destroy, inverse_of: :authorizable
    has_many :users, through: :roles

    scope :with_related_users_included, -> { includes(roles: :users) }
    scope :of_interest_to, ->(user) { joins(:users).where(users: { id: user }).distinct }
  end

  class_methods do
    def role_relation(name, role_name)
      scope name.to_sym,
            lambda { |user| joins(:roles, :users).where(roles: { name: role_name.to_s }, users: { id: user.id }) }
    end
  end
end
