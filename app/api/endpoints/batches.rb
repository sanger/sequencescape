class ::Endpoints::Batches < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:pipeline, :json => "pipeline")
  end
end
