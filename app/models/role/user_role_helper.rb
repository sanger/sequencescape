# frozen_string_literal: true

# Provides the has_role method used to define a number of role helper methods
module Role::UserRoleHelper
  extend ActiveSupport::Concern

  # Checks if the user has the role role_name, in cases like
  # owner, authorizable should indicate the owned resource
  # @return [Boolean] Returns true if the user has the role
  def role?(role_name, authorizable = nil)
    if roles.loaded?
      roles.any? { |role| role.name == role_name.to_s && role.authorizes?(authorizable) }
    else
      roles.named(role_name).authorizing(authorizable).exists?
    end
  end

  # Grants a user the role_name,  in cases like
  # owner, authorizable should indicate the owned resource
  def grant_role(role_name, authorizable = nil)
    roles << Role.find_or_create_by!(name: role_name, authorizable:)
  end

  def remove_role(role_name, authorizable = nil)
    # In practice, we only expect to see one role here
    role = roles.named(role_name).authorizing(authorizable)
    return unless role

    roles.destroy(role)
    role.each(&:destroy_if_empty)
  end

  def role_names
    roles.uniq.pluck(:name)
  end

  class_methods do
    # Defines a potential role for the user. Provides the following methods
    # - role_name? - Returns true if the user has the role
    # - role_name_of? - Alias of role_name
    # - grant_role_name - Assigns the role to the user
    # @!macro [attach] dm.has_role
    #   @!method $1?
    #     @return [Boolean] Returns true if the user has the role $1
    #   @!method $1_of?
    #     @return [Boolean] Returns true if the user has the role $1
    #   @!method grant_$1(role_name, authorizable)
    #     @return [Boolean] Returns true if the user has the role $1
    #
    # @note Disabling Naming/PredicateName as this is not a predicate, but instead has been named
    #       to evoke the behaviour of has_many/has_one
    def has_role(role_name) # rubocop:disable Naming/PredicateName
      define_method(:"#{role_name}?") { |authorizable = nil| role?(role_name, authorizable) }
      alias_method :"#{role_name}_of?", :"#{role_name}?"
      define_method(:"grant_#{role_name}") { |authorizable = nil| grant_role(role_name, authorizable) }
    end
  end
end
