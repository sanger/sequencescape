# frozen_string_literal: true
# Controls API V1 {::Core::Endpoint::Base endpoints} for PlateTemplates
class Endpoints::PlateTemplates < Core::Endpoint::Base
  model {}

  instance { has_many(:wells, json: 'wells', to: 'wells', scoped: 'for_api_plate_json.in_row_major_order') }
end
