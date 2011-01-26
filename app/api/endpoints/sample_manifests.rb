class ::Endpoints::SampleManifests < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:study, :json => "study")
    belongs_to(:supplier, :json => "supplier")
    has_many(:samples, :include => [], :json => "samples", :to => "samples")

  end
end
