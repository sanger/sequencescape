# frozen_string_literal: true

Then /^there should be (\d+) pre capture pools$/ do |pools|
  assert_equal pools.to_i, PreCapturePool.count
end

Then /^the wells from plate with barcode "([^"]*)" should be pooled in column order for 53788839$/ do |plate_barcode|
  pooled(plate_barcode, 'A1', [])
  pooled(plate_barcode, 'B1', [])
  pooled(plate_barcode, 'C1', ['D1'])
  pooled(plate_barcode, 'E1', ['F1'])
  pooled(plate_barcode, 'G1', [])
  pooled(plate_barcode, 'H1', ['A2'])
  pooled(plate_barcode, 'B2', [])
end

def pooled(plate, well, wells) # rubocop:todo Metrics/AbcSize
  initial_request = Plate.find_from_barcode(plate).wells.located_at(well).first.requests.first
  group = initial_request.next_requests.first.pre_capture_pool
  wells.each do |w|
    other_request = Plate.find_from_barcode(plate).wells.located_at(w).first.requests.first
    group_b = other_request.next_requests.first.pre_capture_pool
    assert_equal group, group_b
  end
end
