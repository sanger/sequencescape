# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

Then /^there should be (\d+) pre capture pools$/ do |pools|
  assert_equal pools.to_i, PreCapturePool.count
end

Then /^the wells should be pooled in column order for 53788839$/ do
  pooled('12345', 'A1', [])
  pooled('12345', 'B1', [])
  pooled('12345', 'C1', ['D1'])
  pooled('12345', 'E1', ['F1'])
  pooled('12345', 'G1', [])
  pooled('12345', 'H1', ['A2'])
  pooled('12345', 'B2', [])
end

def pooled(plate, well, wells)
  initial_request = Plate.find_by(barcode: plate).wells.located_at(well).first.requests.first
  group = Submission.last.next_requests(initial_request).first.pre_capture_pool
  wells.each do |w|
    other_request = Plate.find_by(barcode: plate).wells.located_at(w).first.requests.first
    group_b = Submission.last.next_requests(other_request).first.pre_capture_pool
    assert_equal group, group_b
  end
end
