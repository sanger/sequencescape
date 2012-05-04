Given /^sequencescape is setup for 5004860$/ do
  sample   = Factory(:sample_tube)
  library1 = Factory(:empty_library_tube, :qc_state => 'pending')
  library1.parents << sample
  lane = Factory :lane, :qc_state => 'pending'
  request_one = Factory :request, :asset => library1, :target_asset => lane, :state => 'passed'

  reference = BillingEvent.build_reference(request_one)
  Factory :billing_event, :reference => reference,  :quantity => 7, :kind => "charge"

end
