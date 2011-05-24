class ::Endpoints::Transfers < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:destination, :json => "destination")
    belongs_to(:source, :json => "source")
  end
end
