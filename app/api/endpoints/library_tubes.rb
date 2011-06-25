class ::Endpoints::LibraryTubes < ::Endpoints::Tubes
  instance do
    has_many(:requests,         :json => 'requests', :to => 'requests')
    belongs_to(:source_request, :json => 'source_request')
  end
end
