module Endpoints
  class TransferRequestCollections < ::Core::Endpoint::Base
    model do
      # action(:create, to: :standard_create!)
      action(:create) do |request, response|
        standard_create!(request, response)
      end
    end

    instance do
      belongs_to(:user, json: 'user')
    end
  end
end
