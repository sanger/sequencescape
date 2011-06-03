class ::Endpoints::SampleTubes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:library_tubes, :json => 'library_tubes', :to => 'library_tubes')
    has_many(:requests,      :json => 'requests',      :to => 'requests')
  end
end
