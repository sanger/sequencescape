require File.dirname(__FILE__) + '/exceptions'
require File.dirname(__FILE__) + '/identity'

module Authorization
  module ObjectRolesTable
    module UserExtensions
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_authorized_user(roles_relationship_opts = {})
          has_many :user_role_bindings, class_name: 'Role::UserRole'
          has_many :roles, roles_relationship_opts.merge(through: :user_role_bindings, source: :role)
          #          has_and_belongs_to_many :roles, roles_relationship_opts
          include Authorization::ObjectRolesTable::UserExtensions::InstanceMethods
          include Authorization::Identity::UserExtensions::InstanceMethods # Provides all kinds of dynamic sugar via method_missing
        end
      end

      module InstanceMethods
        # If roles aren't explicitly defined in user class then check roles table
        def has_role?(role_name, authorizable_obj = nil)
          if authorizable_obj.nil?
            roles.find_by(name: role_name) || roles.member?(get_role(role_name, authorizable_obj)) ? true : false # If we ask a general role question, return true if any role is defined.
          else
            role = get_role(role_name, authorizable_obj)
            role ? roles.exists?(role.id) : false
          end
        end

        def has_role(role_name, authorizable_obj = nil)
          role = get_role(role_name, authorizable_obj)
          if role.nil?
            role = if authorizable_obj.is_a? Class
              Role.create(name: role_name, authorizable_type: authorizable_obj.to_s)
                   elsif authorizable_obj
              Role.create(name: role_name, authorizable: authorizable_obj)
                   else
              Role.create(name: role_name)
                   end
          end
          roles << role if role and not roles.exists?(role.id)
        end

        def has_no_role(role_name, authorizable_obj = nil)
          role = get_role(role_name, authorizable_obj)
          delete_role(role)
        end

        def has_roles_for?(authorizable_obj)
          if authorizable_obj.is_a? Class
            !roles.detect { |role| role.authorizable_type == authorizable_obj.to_s }.nil?
          elsif authorizable_obj
            !roles.detect { |role| role.authorizable_type == authorizable_obj.class.base_class.to_s && role.authorizable == authorizable_obj }.nil?
          else
            !roles.detect { |role| role.authorizable.nil? }.nil?
          end
        end
        alias :has_role_for? :has_roles_for?

        def roles_for(authorizable_obj)
          if authorizable_obj.is_a? Class
            roles.select { |role| role.authorizable_type == authorizable_obj.to_s }
          elsif authorizable_obj
            roles.select { |role| role.authorizable_type == authorizable_obj.class.base_class.to_s && role.authorizable.id == authorizable_obj.id }
          else
            roles.select { |role| role.authorizable.nil? }
          end
        end

        def has_no_roles_for(authorizable_obj = nil)
          roles_for(authorizable_obj).each { |role| delete_role(role) }
        end

        def has_no_roles
          roles.each { |role| delete_role(role) }
        end

        def authorizables_for(authorizable_class)
          unless authorizable_class.is_a? Class
            raise CannotGetAuthorizables, "Invalid argument: '#{authorizable_class}'. You must provide a class here."
          end
          begin
            authorizable_class.find(
              roles.where(authorizable_type: authorizable_class.base_class.to_s).map(&:authorizable_id).uniq
            )
          rescue ActiveRecord::RecordNotFound
            []
          end
        end

        private

        def get_role(role_name, authorizable_obj)
          if authorizable_obj.is_a? Class
            Role.where(
              name: role_name,
              authorizable_type: authorizable_obj.to_s,
              authorizable_id: nil
            ).first
          elsif authorizable_obj
            Role.where(
              name: role_name,
              authorizable_type: authorizable_obj.class.base_class.to_s,
              authorizable_id: authorizable_obj.id
            ).first
          else
            Role.where(
              name: role_name,
              authorizable_type: nil,
              authorizable_id: nil
            ).first
          end
        end

        def delete_role(role)
          if role
            roles.delete(role)
            role.destroy if role.users.empty?
          end
        end
      end
    end

    module ModelExtensions
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods
        def acts_as_authorizable
          has_many :accepted_roles, as: :authorizable, class_name: 'Role', dependent: :destroy

          has_many :users, through: :roles

          def accepts_role?(role_name, user)
            user.has_role? role_name, self
          end

          def accepts_role(role_name, user)
            user.has_role role_name, self
          end

          def accepts_no_role(role_name, user)
            user.has_no_role role_name, self
          end

          def accepts_roles_by?(user)
            user.has_roles_for? self
          end
          alias :accepts_role_by? :accepts_roles_by?

          def accepted_roles_by(user)
            user.roles_for self
          end

          def authorizables_by(user)
            user.authorizables_for self
          end

          include Authorization::ObjectRolesTable::ModelExtensions::InstanceMethods
          include Authorization::Identity::ModelExtensions::InstanceMethods # Provides all kinds of dynamic sugar via method_missing
        end
      end

      module InstanceMethods
        # If roles aren't overriden in model then check roles table
        def accepts_role?(role_name, user)
          user.has_role? role_name, self
        end

        def accepts_role(role_name, user)
          user.has_role role_name, self
        end

        def accepts_no_role(role_name, user)
          user.has_no_role role_name, self
        end

        def accepts_roles_by?(user)
          user.has_roles_for? self
        end
        alias :accepts_role_by? :accepts_roles_by?

        def accepted_roles_by(user)
          user.roles_for self
        end
      end
    end
  end
end
