Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = Factory(:study, :id => study_id, :name => 'Study 999')
  project = Factory(:project, :id => 1)
  request_type = RequestType.find_by_key('library_creation')
  request = Factory(:request, :id => request_id,
                    :study => study, :project => project, :request_type => request_type)
end

Given /^I have a request (\d+) without a request type$/ do |request_id|
  study = Factory(:study, :id => 999, :name => 'Study 999')
  project = Factory(:project, :id => 1)
  request = Factory(:request, :id => request_id,
    :study => study, :project => project)
  request.update_attributes!(:request_type => nil)
end
