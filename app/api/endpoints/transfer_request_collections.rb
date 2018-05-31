module Endpoints
  class TransferRequestCollections < ::Core::Endpoint::Base
    model do
      action(:create, to: :standard_create!)
    end

    instance do
      belongs_to(:user, json: 'user')
    end
  end
end
