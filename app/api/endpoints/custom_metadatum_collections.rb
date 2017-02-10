# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

class ::Endpoints::CustomMetadatumCollections < ::Core::Endpoint::Base
  model do
    action(:create, to: :standard_create!)
  end

  instance do
    belongs_to(:asset, json: 'asset', to: 'asset')
    belongs_to(:user, json: 'user', to: 'user')
    action(:update, to: :standard_update!)
  end
end
