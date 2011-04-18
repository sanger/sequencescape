module ModelExtensions::Project
  def self.included(base)
    base.class_eval do
      has_many :submissions
      named_scope :include_roles, :include => { :roles => :users }
    end
  end

  def roles_as_json
    Hash[
      self.roles.map do |role|
        [ role.name.underscore, role.users.map { |user| { :login => user.login, :email => user.email, :name => user.name } } ]
      end
    ]
  end
end
