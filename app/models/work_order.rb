# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

# A work order groups requests together based on submission and asset
# providing a unified interface for external applications.
# It is likely that its behaviour will be extended in future
class WorkOrder < ActiveRecord::Base
  has_many :requests
  belongs_to :work_order_type, required: true
end
