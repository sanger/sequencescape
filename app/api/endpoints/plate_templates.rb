class ::Endpoints::PlateTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:wells,                     :json => 'wells', :to => 'wells', :scoped => 'for_api_plate_json.in_row_major_order')
  end

end
