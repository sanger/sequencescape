class ::Endpoints::Wells < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:plate, :json => "plate")
    belongs_to(:sample, :json => "sample")
  end
end
