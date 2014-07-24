class ::Endpoints::Lots < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:qcables, :json => 'qcables', :to => 'qcables')
    belongs_to(:lot_type, :json => 'lot_type', :to => 'lot_type')
    belongs_to(:template, :json => 'template', :to => 'template')
  end

end
