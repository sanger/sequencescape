#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class ::Endpoints::LotTypes < ::Core::Endpoint::Base
  model do

  end

  instance do
    has_many(:lots, :json=>'lots', :to=>'lots') do
      action(:create) do |request,_|
        ActiveRecord::Base.transaction do
          request.target.proxy_association.owner.create!(request.attributes)
        end
      end
    end
  end

end
