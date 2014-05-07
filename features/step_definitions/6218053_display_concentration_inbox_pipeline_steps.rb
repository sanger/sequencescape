Given /^Pipeline "([^"]*)" and a setup for 6218053$/ do |name|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline '#{ name }'"
  asset_type = pipeline_name_to_asset_type(name)
  request_type = pipeline.request_types.detect {|rt| !rt.deprecated }
  metadata = Factory :"request_metadata_for_#{request_type.key}"
  request  = Factory :request, :request_type => request_type, :asset => Factory(asset_type), :request_metadata => metadata
  request.asset.location    = pipeline.location
  request.asset.save!

end
