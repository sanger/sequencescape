class ::Endpoints::SampleTubes < ::Endpoints::Tubes
  instance do
    has_many(:requests,      :json => 'requests',      :to => 'requests')
    has_many(:library_tubes, :json => 'library_tubes', :to => 'library_tubes')
  end
end
