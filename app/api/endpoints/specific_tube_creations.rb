# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

class ::Endpoints::SpecificTubeCreations < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    has_many(:children, json: 'children', to: 'children')
    has_many(:child_purposes, json: 'child_purposes', to: 'child_purposes')
    belongs_to(:parent, json: 'parent')
    belongs_to(:user, json: 'user')
  end
end
