Given /^sequencescape is setup for 4759010$/ do
  group = Factory(:tag_group, :name => 'Tag group for 4759010')
  group.tags << Factory(:tag, :oligo => 'Tag for 4759010')
end

Given /^a batch in "Cluster formation PE" has been setup for feature 4759010$/ do         
  pending
end

Given /^a batch in "MX Library Preparation \[NEW\]" has been setup for feature 4759010$/ do         
  pipeline = Pipeline.find_by_name("MX Library Preparation [NEW]") or raise StandardError, "Cannot find pipeline '#{ name }'"
  batch    = Factory :batch, :pipeline => pipeline, :state => :started
  
  submission = Factory :submission
  
  asset_group = Factory(:asset_group)

  asset_type = pipeline_name_to_asset_type(pipeline.name)
                                   
  10.times do |_|
    request  = Factory :request, :request_type => pipeline.request_type, :submission_id => submission.id, :asset => Factory(asset_type)
    request.asset.location    = pipeline.location   
    request.asset.save!
    batch.requests << request 
    asset_group.assets << request.asset       
  end
                                                     
  pipeline = Pipeline.find_by_name("Cluster formation PE") or raise StandardError, "Cannot find pipeline '#{ name }'"
  
  request  = Factory :request, :request_type => pipeline.request_type, :submission_id => submission.id, :asset => Factory(asset_type)
  request.asset.location    = pipeline.location
  request.asset.save!
  batch.requests << request
  asset_group.assets << request.asset       
end    
 
When /^I select all requests$/ do 
 page.all('.request_checkbox').each { |checkbox| checkbox.set(true) }
end
