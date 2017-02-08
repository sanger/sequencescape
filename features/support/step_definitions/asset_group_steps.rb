# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

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

Then /^the assets in the asset group "([^\"]+)" should only be in that group$/ do |name|
  asset_group = AssetGroup.find_by(name: name) or raise StandardError, "Cannot find the asset group #{name.inspect}"
  assert_equal([asset_group], asset_group.assets.map(&:asset_groups).flatten.uniq, 'Assets in more asset groups')
end

Then /^the asset group with the name from the last order UUID value contains the assets for the following samples:$/ do |table|
  # TODO[mb14] rename
  order = Order.last or raise StandardError, 'There are no order!'
  asset_group = AssetGroup.find_by(name: order.uuid) or raise StandardError, 'Could not find the asset group for the last submission'
  assets      = Sample.where(name: table.raw.map(&:first)).map(&:assets).flatten
  assert_equal(assets.map(&:id), asset_group.assets.map(&:id), 'Assets in the asset group are not correct')
end
