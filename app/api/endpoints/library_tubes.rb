#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class ::Endpoints::LibraryTubes < ::Endpoints::Tubes
  instance do
    has_many(:requests,         :json => 'requests', :to => 'requests')
    belongs_to(:source_request, :json => 'source_request')
  end
end
