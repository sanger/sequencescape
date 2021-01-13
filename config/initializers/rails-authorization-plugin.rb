# NOTE : If you use modular controllers like '/admin/products' be sure
# to redirect to something like '/sessions' controller (with a leading slash)
# as shown in the example below or you will not get redirected properly
#
# This can be set to a hash or to an explicit path like '/login'
#

# You can perform authorization at varying degrees of complexity.
# Choose a style of authorization below (see README.txt) and the appropriate
# mixin will be used for your app.

require 'rails-authorization-plugin/lib/publishare/object_roles_table'
ActiveRecord::Base.send(:include,
                        Authorization::ObjectRolesTable::UserExtensions,
                        Authorization::ObjectRolesTable::ModelExtensions)
