class ::Endpoints::Tube::Purposes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:child_purposes, :json => 'children', :to => 'children')
    has_many(:tubes, :json => 'tubes', :to => 'tubes')
  end
end
