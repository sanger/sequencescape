Given /^Pipeline "([^"]*)" and a setup for 6218053$/ do |name|
 pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline '#{ name }'"
asset_type = pipeline_name_to_asset_type(name)

 1.times do
   request  = Factory :request, :request_type => pipeline.request_types.last, :asset => Factory(asset_type)
   request.asset.location    = pipeline.location
   request.asset.save!
 end

end
