class ::Endpoints::PlateConversions < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:target,  :json => "target")
    belongs_to(:purpose, :json => "purpose")
    belongs_to(:user,    :json => "user")
    belongs_to(:parent,  :json => "parent")
  end
end
