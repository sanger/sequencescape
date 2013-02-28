class ::Endpoints::BulkTransfers < ::Core::Endpoint::Base
  model do
    action(:create, :to => :standard_create!)
  end

  instance do
    belongs_to(:user, :json => "user")
    has_many(:transfers, :json => "transfers", :to =>"transfers")
  end
end
