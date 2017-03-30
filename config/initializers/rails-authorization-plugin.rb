require 'rails-authorization-plugin/lib/authorization'

ActionController::Base.send(:include, Authorization::Base)
ActionView::Base.send(:include, Authorization::Base::ControllerInstanceMethods)

# Can be 'object roles' or 'hardwired'
AUTHORIZATION_MIXIN = 'object roles'

# NOTE : If you use modular controllers like '/admin/products' be sure
# to redirect to something like '/sessions' controller (with a leading slash)
# as shown in the example below or you will not get redirected properly
#
# This can be set to a hash or to an explicit path like '/login'
#
LOGIN_REQUIRED_REDIRECTION = { controller: '/sessions', action: 'login' }
PERMISSION_DENIED_REDIRECTION = { controller: '/home', action: 'index' }

# The method your auth scheme uses to store the location to redirect back to
STORE_LOCATION_METHOD = :store_location

# You can perform authorization at varying degrees of complexity.
# Choose a style of authorization below (see README.txt) and the appropriate
# mixin will be used for your app.

require 'rails-authorization-plugin/lib/publishare/object_roles_table'
ActiveRecord::Base.send(:include,
  Authorization::ObjectRolesTable::UserExtensions,
  Authorization::ObjectRolesTable::ModelExtensions)
