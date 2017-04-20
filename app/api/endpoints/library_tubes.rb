# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

class ::Endpoints::LibraryTubes < ::Endpoints::Tubes
  instance do
    belongs_to(:custom_metadatum_collection, json: 'custom_metadatum_collection', to: 'custom_metadatum_collection')
    belongs_to(:purpose, json: 'purpose')
    has_many(:requests,         json: 'requests', to: 'requests')
    belongs_to(:source_request, json: 'source_request')
  end
end
