# Included in {Project}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Project
  def self.included(base)
    base.class_eval do
      has_many :submissions
      scope :include_roles, -> { includes(roles: :users) }
    end
  end

  def roles_as_json
    Hash[
      roles.map do |role|
        [role.name.underscore, role.users.map { |user| { login: user.login, email: user.email, name: user.name } }]
      end
    ]
  end
end
