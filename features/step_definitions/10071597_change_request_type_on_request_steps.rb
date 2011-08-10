Given /^sequencescape is setup for 10071597$/ do
 project = Factory :project, :name => "Test project 10071597", :enforce_quotas => true   
 lane = Factory :lane, :name => "NPG_Action_Lane_Test", :qc_state => 'passed'
 library_tube = Factory :empty_library_tube
 request_type = RequestType.find_by_name("Paired end sequencing") 
 request = Factory :request, :asset => library_tube, :target_asset => lane, :state => 'pending', :project => project, :request_type => request_type
end

Given /^last request the state "([^"]*)"$/ do |state|
 request = Request.last
 request.state = state
 request.save
end

Given /^last request enough quota$/ do
  request = Request.last
  request.project.enforce_quotas = false
  request.project.save  
end

