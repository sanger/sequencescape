class ::Endpoints::PlateCreations < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:child, :json => "child")
    belongs_to(:child_plate_purpose, :json => "child_plate_purpose")
    belongs_to(:parent, :json => "parent")
    belongs_to(:user, :json => "user")
  end
end
