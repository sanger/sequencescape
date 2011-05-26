class ::Endpoints::StateChanges < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
    action_requires_authorisation(:create)
  end

  instance do
    belongs_to(:target, :json => "target")
    belongs_to(:user, :json => "user")
  end
end
