# Defines named roles for users that may be applied to
# objects in a polymorphic fashion. For example, you could create a role
# "moderator" for an instance of a model (i.e., an object), a model class,
# or without any specification at all.
class Role < ActiveRecord::Base
  has_and_belongs_to_many :users
  belongs_to :authorizable, :polymorphic => true

  validates_presence_of :name
  
  def self.keys
    Role.all.map { |r| r.name }.uniq
  end

  def self.general_roles
    Role.all.select{|role| role.authorizable.nil?}
  end

  # Include this module into your ActiveRecord model and get has_many roles and some
  # utility named_scopes.  You also get the ability to define role relations by name
  # through the role_relation class method.
  module Authorized
    def self.included(base)
      base.extend(ClassMethods)
      base.instance_eval do
        has_many :roles, :as => :authorizable

        named_scope :with_related_users_included, { :include => { :roles => :users } }
        named_scope :of_interest_to, lambda { |user|
          {
            :joins      => { :roles => :users },
            :conditions => { :roles => { :users => { :id => user.id } } },
            :group => "roles.authorizable_id"
          }
        }
      end
    end

    module ClassMethods
      def role_relation(name, role_name)
        named_scope name.to_sym, lambda { |user|
          {
            :joins      => { :roles => :users },
            :conditions => {
              :roles => {
                :name  => role_name.to_s,
                :users => { :id => user.id }
              }
            }
          }
        }
      end

      def has_many_users_through_roles(name)
        define_method(name.to_s.pluralize.to_sym) do 
          role = self.roles.find_by_name(name.to_s.singularize)
          role.nil? ? [] : role.users
        end
      end
    end
  end
end
