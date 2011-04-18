Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = Factory(:study, :id => study_id, :name => 'Study 999')
  sample = Factory(:sample, :id => 1)
  project = Factory(:project, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request, :id => request_id)
  request.update_attributes!(:study => study, :sample => sample, :project => project, :request_type => request_type)
end

Given /^I have a request (\d+) without a study$/ do |request_id|
  sample = Factory(:sample, :id => 1)
  project = Factory(:project, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request, :id => request_id)
  request.update_attributes!( :sample => sample, :project => project, :request_type => request_type, :study => nil)
end


Given /^I have a request (\d+) without a project$/ do |request_id|
  study = Factory(:study, :id => 999, :name => 'Study 999')
  sample = Factory(:sample, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request, :id => request_id)
  request.update_attributes!(:study => study, :sample => sample, :request_type => request_type, :project => nil)
end

Given /^I have a request (\d+) without a request type$/ do |request_id|
  study = Factory(:study, :id => 999, :name => 'Study 999')
  sample = Factory(:sample, :id => 1)
  project = Factory(:project, :id => 1)
  request = Factory(:request, :id => request_id)
  request.update_attributes!(:study => study, :sample => sample, :project => project, :request_type => nil)
end
