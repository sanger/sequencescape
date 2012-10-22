class ::Endpoints::TubeCreations < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    has_many(:children, :json => "children", :to => "children")
    belongs_to(:child_purpose, :json => "child_purpose")
    belongs_to(:parent, :json => "parent")
    belongs_to(:user, :json => "user")
  end
end
