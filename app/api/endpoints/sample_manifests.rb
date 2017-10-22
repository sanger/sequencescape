# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class ::Endpoints::SampleManifests < ::Core::Endpoint::Base
  model do
    # TODO: For the moment we have to disable the read functionality as it consumes too much memory.
    # Loading a sample manifest of only a few thousand samples causes the memory to spike at 1.2GB
    # and when you have 10s of these in a 100 entry page of results that is not good.
    disable :read
  end

  instance do
    belongs_to(:study, json: 'study')
    belongs_to(:supplier, json: 'supplier')

    action(:update) do |request, _response|
      ActiveRecord::Base.transaction do
        request.target.tap do |manifest|
          manifest.update_attributes!(request.attributes(request.target), request.user)
        end
      end
    end
  end
end
