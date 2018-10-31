Given /^sequencescape is setup for 5004860$/ do
  sample   = FactoryBot.create(:sample_tube)
  library1 = FactoryBot.create(:empty_library_tube, qc_state: 'pending')
  library1.parents << sample
  lane = FactoryBot.create :lane, qc_state: 'pending'
  request_one = FactoryBot.create :request_with_sequencing_request_type, asset: library1, target_asset: lane, state: 'passed'
end
