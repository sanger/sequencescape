class ::Endpoints::Tubes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:requests, :json => 'requests', :to => 'requests')
    belongs_to(:purpose, :json => 'purpose')
  end
end
