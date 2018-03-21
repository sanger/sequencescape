# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

# TransferRequests are exposed via the API and allow
# you to access their source and target assets, and their submissions
class ::Endpoints::TransferRequests < ::Core::Endpoint::Base
  model do
  end

  instance do
    belongs_to(:asset,        json: 'source_asset')
    belongs_to(:target_asset, json: 'target_asset')
    belongs_to(:submission,   json: 'submission')
  end
end
