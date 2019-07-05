Given '{study_name} has an asset group called {string}' do |study, group_name|
  study.asset_groups.create!(name: group_name)
end

Given '{asset_name} is in {asset_group}' do |tube, asset_group|
  asset_group.assets << tube.receptacle
end

Then '{asset_group} should only contain {asset_name}' do |asset_group, sample_tube|
  assert_equal([sample_tube], asset_group.assets, 'Sample tube is not in the asset group')
end

Then '{asset_name} should only be in {asset_group}' do |sample_tube, asset_group|
  assert_equal([asset_group], sample_tube.asset_groups, 'Sample tube has different asset groups')
end
