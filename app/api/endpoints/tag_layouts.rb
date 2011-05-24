class ::Endpoints::TagLayouts < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:plate, :json => "plate")
  end
end
