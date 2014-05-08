class ::Endpoints::Qcables < ::Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:asset,  :json => 'asset')
    belongs_to(:lot,    :json => 'lot')
  end

end
