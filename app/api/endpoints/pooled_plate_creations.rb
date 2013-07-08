class ::Endpoints::PooledPlateCreations < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:child, :json => "child")
    belongs_to(:child_purpose, :json => "child_purpose")
    has_many(:parents, :json => "parents", :to=> "parents")
    belongs_to(:user, :json => "user")
  end
end
