# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^sequencescape is setup for 5004860$/ do
  sample   = FactoryBot.create(:sample_tube)
  library1 = FactoryBot.create(:empty_library_tube, qc_state: 'pending')
  library1.parents << sample
  lane = FactoryBot.create :lane, qc_state: 'pending'
  request_one = FactoryBot.create :request_with_sequencing_request_type, asset: library1, target_asset: lane, state: 'passed'
end
