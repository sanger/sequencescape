class ::Endpoints::StateChanges < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:target, :json => "target")
    belongs_to(:user, :json => "user")
  end
end
