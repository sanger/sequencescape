#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ::Endpoints::Lots < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:qcables, :json => 'qcables', :to => 'qcables')
    belongs_to(:lot_type, :json => 'lot_type', :to => 'lot_type')
    belongs_to(:template, :json => 'template', :to => 'template')
  end

end
