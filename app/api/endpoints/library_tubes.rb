class ::Endpoints::LibraryTubes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:requests,         :json => 'requests', :to => 'requests')
    belongs_to(:sample,         :json => 'sample')
    belongs_to(:source_request, :json => 'source_request')
  end
end
