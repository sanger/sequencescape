# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order type is a simple string identifier of the entire work order
# As initial work orders correspond to single request workflow it will initially
# reflect the request type of the provided request.
class WorkOrderType < ActiveRecord::Base
  validates :name,
            presence: true,
            # Format constraints are intended mainly to keep things consistent, especially with request type keys.
            format: { with: /\A[a-z0-9_]+\z/, message: 'should only contain lower case letters, numbers and underscores.' },
            uniqueness: true
end
