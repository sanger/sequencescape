require_relative 'identity'

module Authorization
  module ObjectRolesTable
    module UserExtensions # rubocop:todo Style/Documentation
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods # rubocop:todo Style/Documentation
        def acts_as_authorized_user(roles_relationship_opts = {})
          has_many :user_role_bindings, class_name: 'Role::UserRole'
          has_many :roles, roles_relationship_opts.merge(through: :user_role_bindings, source: :role)
          include Authorization::ObjectRolesTable::UserExtensions::InstanceMethods
          include Authorization::Identity::UserExtensions::InstanceMethods
        end
      end

      module InstanceMethods # rubocop:todo Style/Documentation
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
          destroy_role(role)
        end

        private

        def get_role(role_name, authorizable_obj)
          Role.find_by(
            name: role_name,
            authorizable: authorizable_obj
          )
        end

        def destroy_role(role)
          if role
            roles.destroy(role)
            role.destroy if role.users.empty?
          end
        end
      end
    end

    module ModelExtensions # rubocop:todo Style/Documentation
      def self.included(recipient)
        recipient.extend(ClassMethods)
      end

      module ClassMethods # rubocop:todo Style/Documentation
        def acts_as_authorizable
          has_many :accepted_roles, as: :authorizable, class_name: 'Role', dependent: :destroy

          has_many :users, through: :roles
        end
      end
    end
  end
end
