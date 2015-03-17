#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ::Endpoints::PlateTemplates < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:wells,                     :json => 'wells', :to => 'wells', :scoped => 'for_api_plate_json.in_row_major_order')
  end

end
