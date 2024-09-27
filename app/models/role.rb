# frozen_string_literal: true

# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ApplicationRecord
  has_many :user_role_bindings, class_name: 'Role::UserRole', dependent: :destroy
  has_many :users, through: :user_role_bindings, source: :user

  belongs_to :authorizable, polymorphic: true, touch: true

  validates :name, presence: true
  scope :general_roles, -> { where(authorizable_type: nil) }
  scope :named, ->(name) { where(name:) }
  scope :authorizing, ->(authorizable) { where(authorizable:) if authorizable }

  after_destroy :touch_authorizable

  def self.keys
    distinct.pluck(:name)
  end

  def destroy_if_empty
    destroy if users.empty?
  end

  def touch_authorizable
    authorizable&.touch # rubocop:disable Rails/SkipsModelValidations
  end

  #
  # Returns the true if the role authorizes check.
  # If check is a class, returns true is the authorizable is that class, otherwise
  # checks the equality.
  #
  # @param check [Class,ApplicationRecord] The authorize to check against
  #
  # @return [<Type>] <description>
  #
  def authorizes?(check)
    case check
    when nil
      true
    when Class
      authorizable.is_a?(check)
    else
      check == authorizable
    end
  end
end
