Given /^sequencescape is setup for 5600990$/ do
 lane = Factory :lane, :name => "NPG_Action_Lane_Test", :qc_state => 'passed', :external_release => 1
 library_tube = Factory :empty_library_tube

 request = Factory :request_with_sequencing_request_type, :asset => library_tube, :target_asset => lane, :state => 'started'

 batch = Factory :batch, :state => 'started', :qc_state => 'qc_manual'
 Factory :batch_request, :request => request, :batch => batch, :position => 1
end

Given /^a second request$/ do
 lane = Lane.find_by_name("NPG_Action_Lane_Test")
 library_tube = Factory :empty_library_tube
 request = Factory :request_with_sequencing_request_type, :asset => library_tube, :target_asset => lane
end

Given /^a billing event to the request$/ do
 lane = Lane.find_by_name("NPG_Action_Lane_Test")
 request = lane.source_request
 BillingEvent.send(:map_for_each_aliquot, request) do |aliquot_info|
   reference = BillingEvent.build_reference(request, aliquot_info)
   Factory :billing_event, :reference => reference,  :quantity => 1, :kind => "charge"
   Factory :billing_event, :reference => reference,  :quantity => 1, :kind => "refund"
 end
end

Given /^an event to the request$/ do
 lane = Lane.find_by_name("NPG_Action_Lane_Test")
 request = lane.source_request
 Factory :event, :eventful => request, :created_by =>'npg'
end

When /^I (POST|PUT) following XML to change the QC state on the last asset:$/ do |action, xml|
 lane = Lane.last
 When %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/fail_qc_state":}, xml
end

When /^I (POST|PUT) following XML to change in passed the QC state on the last asset:$/ do |action, xml|
 lane = Lane.last
 When %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/pass_qc_state":}, xml
end

When /^I (POST|PUT) following XML to change the QC state on the asset that does not exist:$/ do |action, xml|
 When %Q{I #{action} the following XML to "/npg_actions/assets/9999999999/fail_qc_state":}, xml
end
