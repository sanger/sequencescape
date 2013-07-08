class ::Endpoints::SpecificTubeCreations < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    has_many(:children, :json => "children", :to => "children")
    has_many(:child_purposes, :json => "child_purposes", :to => "child_purposes")
    belongs_to(:parent, :json => "parent")
    belongs_to(:user, :json => "user")
  end
end
