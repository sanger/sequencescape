#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2014 Genome Research Ltd.
class Endpoints::Orders < Core::Endpoint::Base
  model do

  end

  instance do
    belongs_to(:project, :json => 'project')
    belongs_to(:study,   :json => 'study')
    belongs_to(:user,    :json => 'user')

    action(:update, :to => :standard_update!, :if => :building?)
  end
end
