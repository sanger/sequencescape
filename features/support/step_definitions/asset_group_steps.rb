Given /^the study "([^\"]+)" has an asset group called "([^\"]+)"$/ do |study_name, group_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Could not find study #{study_name.inspect}"
  study.asset_groups.create!(name: group_name)
end

Given /^the sample tube "([^\"]+)" is in the asset group "([^\"]+)"$/ do |tube_name, group_name|
  asset_group = AssetGroup.find_by(name: group_name) or raise StandardError, "Could not find asset group #{group_name.inspect}"
  sample_tube = SampleTube.find_by(name: tube_name) or raise StandardError, "Could not find sample tube #{tube_name.inspect}"
  asset_group.assets << sample_tube
end

Then /^the asset group "([^\"]+)" should only contain sample tube "([^\"]+)"$/ do |group_name, tube_name|
  asset_group = AssetGroup.find_by(name: group_name) or raise StandardError, "Could not find asset group #{group_name.inspect}"
  sample_tube = SampleTube.find_by(name: tube_name) or raise StandardError, "Could not find sample tube #{tube_name.inspect}"
  assert_equal([sample_tube], asset_group.assets, 'Sample tube is not in the asset group')
end

Then /^the sample tube "([^\"]+)" should only be in asset group "([^\"]+)"$/ do |tube_name, group_name|
  asset_group = AssetGroup.find_by(name: group_name) or raise StandardError, "Could not find asset group #{group_name.inspect}"
  sample_tube = SampleTube.find_by(name: tube_name) or raise StandardError, "Could not find sample tube #{tube_name.inspect}"
  assert_equal([asset_group], sample_tube.asset_groups, 'Sample tube has different asset groups')
end
