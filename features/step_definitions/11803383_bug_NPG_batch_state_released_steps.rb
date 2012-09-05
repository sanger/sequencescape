Given /^sequencescape is setup for 11803383$/ do
 lane = Factory :lane, :name => "NPG_Action_Lane_Test", :qc_state => 'passed', :external_release => 1
 library_tube = Factory :library_tube
 pipeline = Pipeline.find_by_name("Cluster formation PE")
 request = Factory :request, :asset => library_tube, :target_asset => lane, :request_type => pipeline.request_types.last, :state => 'started'

 batch = Factory :batch, :state => 'started', :qc_state => 'qc_manual', :pipeline => pipeline
 Factory :batch_request, :request => request, :batch => batch, :position => 1
end


Then /^batch state should be "([^"]*)"$/ do |state|
  batch = Batch.last
  assert_equal batch.state, state
end
