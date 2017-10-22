# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

class ::Endpoints::Suppliers < ::Core::Endpoint::Base
  model do
  end

  instance do
    has_many(:sample_manifests, include: [], json: 'sample_manifests', to: 'sample_manifests')
  end
end
