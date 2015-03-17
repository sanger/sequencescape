#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
class ::Endpoints::AssetAudits < ::Core::Endpoint::Base
  model do
    action(:create) do |request, response|
      request.create!
    end
  end

  instance do
    belongs_to(:asset, :json => "asset")
  end
end
