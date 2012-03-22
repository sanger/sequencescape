
Given /^I have a billing event with UUID "([^"]*)" and a bait library$/ do |uuid_value|
  project = Factory :project, :name => "Test Project"
  Given %Q{the project "Test Project" a budget division "Human variation"}
  request = Request.create!(:request_type => RequestType.find_by_key('paired_end_sequencing'))
  request.request_metadata.update_attributes!(:read_length => 100, :library_type => "Standard", :bait_library_id => 1 )
  billing_event = Factory :billing_event, :project => project, :request => request
  set_uuid_for(billing_event, uuid_value)
end

Given /^the (sample|library) tube "([^\"]+)" has been involved in a "([^\"]+)" request with the bait library "([^\"]+)" within the study "([^\"]+)" for the project "([^\"]+)"$/ do |tube_type, tube_name, request_type_name, bait_library_name, study_name, project_name|
  study        = Study.find_by_name(study_name) or raise StandardError, "Cannot find study named #{ study_name.inspect }"
  project      = Project.find_by_name(project_name) or raise StandardError, "Cannot find the project named #{ project_name.inspect }"
  request_type = RequestType.find_by_name(request_type_name) or raise StandardError, "Cannot find request type #{ request_type_name.inspect }"
  asset = "#{ tube_type }_tube".camelize.constantize.find_by_name(tube_name) or raise StandardError, "Cannot find #{ tube_type } tube named #{ tube_name.inspect }"
  target_asset = Factory(request_type.asset_type.underscore, :name => "#{ study_name } - Target asset")
  create_request(request_type, study, project, asset, target_asset)
  Request.last.request_metadata.update_attributes(:bait_library_id=>BaitLibrary.find_by_name('Mouse all exon').id)
end
