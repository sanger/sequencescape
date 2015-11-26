# require Rails.root + '/lib/rails-authorization-plugin/lib/authorization'
ActionController::Base.send( :include, Authorization::Base )
ActionView::Base.send( :include, Authorization::Base::ControllerInstanceMethods )

# You can perform authorization at varying degrees of complexity.
# Choose a style of authorization below (see README.txt) and the appropriate
# mixin will be used for your app.

# When used with the auth_test app, we define this in config/environment.rb
# AUTHORIZATION_MIXIN = "hardwired"
if not Object.constants.include? :AUTHORIZATION_MIXIN
  AUTHORIZATION_MIXIN = "object roles"
end

case AUTHORIZATION_MIXIN
  when "hardwired"
    require Rails.root.to_s + '/lib/rails-authorization-plugin/lib/publishare/hardwired_roles'
    ActiveRecord::Base.send( :include,
      Authorization::HardwiredRoles::UserExtensions,
      Authorization::HardwiredRoles::ModelExtensions
    )
  when "object roles"
    require Rails.root.to_s + '/lib/rails-authorization-plugin/lib/publishare/object_roles_table'
    ActiveRecord::Base.send( :include,
      Authorization::ObjectRolesTable::UserExtensions,
      Authorization::ObjectRolesTable::ModelExtensions
    )
end
