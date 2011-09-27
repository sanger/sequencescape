Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = Factory(:study, :id => study_id, :name => 'Study 999')
  project = Factory(:project, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request_without_project, :id => request_id)
  request.update_attributes!(:study => study, :project => project, :request_type => request_type)
end

Given /^I have a request (\d+) without a study$/ do |request_id|
  project = Factory(:project, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request_without_project, :id => request_id)
  request.update_attributes!(:project => project, :request_type => request_type, :study => nil)
end


Given /^I have a request (\d+) without a project$/ do |request_id|
  study = Factory(:study, :id => 999, :name => 'Study 999')
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request_without_project, :id => request_id)
  request.update_attributes!(:study => study, :request_type => request_type, :project => nil)
end

Given /^I have a request (\d+) without a request type$/ do |request_id|
  study = Factory(:study, :id => 999, :name => 'Study 999')
  project = Factory(:project, :id => 1)
  request = Factory(:request_without_project, :id => request_id)
  request.update_attributes!(:study => study, :project => project, :request_type => nil)
end
