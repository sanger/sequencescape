def create_and_bind_asset_to_study(name_asset, name_study)
  asset = Factory :asset, :name => name_asset
  study  = Study.find_by_name(name_study) or raise StandardError, "Cannot find study #{name_study.inspect}"
  asset.studies << study
end

Given /^the asset "([^"]*)" to the study named "([^"]*)"$/ do |name_asset, name_study|
  create_and_bind_asset_to_study(name_asset, name_study)
end
