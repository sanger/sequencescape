# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

class ::Endpoints::Tube::Purposes < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    has_many(:child_purposes, json: 'children', to: 'children')
    has_many(:parent_purposes, json: 'parents', to: 'parents')
    has_many(:tubes, json: 'tubes', to: 'tubes')
  end
end
