class ::Endpoints::SampleManifests < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:study, :json => "study")
    belongs_to(:supplier, :json => "supplier")
  end
end
